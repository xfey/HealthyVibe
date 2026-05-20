import Foundation
import HealthyVibeAgents
import HealthyVibeCore
import HealthyVibeStorage
import HealthyVibeTeam

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedPage: AppPage = .today
    @Published private(set) var setupStatus: SetupStatus = .initializing
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var todayTaskState: TodayTaskState
    @Published private(set) var monthSummaries: [DailyHistorySummary] = []
    @Published private(set) var historyOverview: HistoryOverview
    @Published private(set) var notificationPermissionState: NotificationPermissionState = .unknown
    @Published private(set) var lastReminderMessage: String?
    @Published private(set) var agentConnectionStatuses: [AgentKind: AgentConnectionStatus] = [:]
    @Published private(set) var agentStatusMessage: String?
    @Published private(set) var teamProfile: TeamProfile?
    @Published private(set) var teamRanking: TeamRanking?
    @Published private(set) var teamStatusMessage: String?
    @Published var selectedHistoryDateKey: String?

    let paths: AppPaths
    private let taskEngine: TaskEngine
    private var database: AppDatabase?
    private var notificationService: NotificationService?
    private var activeTimeTracker: ActiveTimeTracker?
    private var hookBridgeManager: HookBridgeManager?
    private var hookEventPollTimer: Timer?
    private var cooldownStartedAt: Date?
    private var reminderSnoozedUntil: Date?
    private let teamRelayClient = TeamRelayClient()
    private let reminderCooldown: TimeInterval = 30 * 60

    init(paths: AppPaths = AppPaths()) {
        let taskEngine = TaskEngine()
        let initialState = taskEngine.makeInitialState()
        self.paths = paths
        self.taskEngine = taskEngine
        self.todayTaskState = initialState
        self.historyOverview = .empty(todayDateKey: initialState.dateKey)
        self.selectedHistoryDateKey = initialState.dateKey
    }

    func bootstrap() {
        do {
            try paths.ensureCreated()
            let database = try AppDatabase(path: paths.databaseURL.path)
            self.database = database
            let hookBridgeManager = HookBridgeManager(
                applicationSupportDirectory: paths.applicationSupportDirectory,
                eventsDirectory: paths.eventsDirectory,
                hooksDirectory: paths.hooksDirectory
            )
            try hookBridgeManager.installBridgeScript()
            self.hookBridgeManager = hookBridgeManager
            agentConnectionStatuses = hookBridgeManager.statuses()
            todayTaskState = try database.loadTodayState()
            teamProfile = try database.loadTeamProfile()
            if let teamProfile {
                teamRanking = try database.loadTeamRankingCache(
                    teamCodeHash: teamProfile.teamCodeHash,
                    date: todayTaskState.dateKey
                )
            }
            cooldownStartedAt = try database.loadReminderCooldownStartedAt()
            reminderSnoozedUntil = try database.loadReminderSnoozedUntil()
            selectedHistoryDateKey = todayTaskState.dateKey
            try reloadHistory()
            try processPendingHookEvents()
            startHookEventPolling()
            setupStatus = .ready
            lastErrorMessage = nil
            AppLog.app.info("HealthyVibe bootstrapped successfully.")
        } catch {
            setupStatus = .failed
            lastErrorMessage = "初始化本地目录失败，请检查 Application Support 权限。"
            AppLog.app.error("Bootstrap failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func attachNotificationService(_ service: NotificationService) {
        notificationService = service
        refreshNotificationPermission()

        let tracker = ActiveTimeTracker()
        tracker.onFallbackDue = { [weak self] in
            self?.handleFallbackReminder()
        }
        tracker.start()
        activeTimeTracker = tracker
    }

    var todayProgressText: String {
        "今日 \(todayTaskState.totalLongevityMinutes) / \(todayTaskState.targetMinutes) 分钟"
    }

    var canSwitchTask: Bool {
        todayTaskState.remainingItems.count > 1 || todayTaskState.currentTask != nil
    }

    func completeCurrentTask() {
        do {
            let completed = try completeCurrentTask(now: Date())
            if completed {
                syncTeamSnapshot()
            }
        } catch {
            recordError("完成任务失败：\(error.localizedDescription)")
        }
    }

    @discardableResult
    private func completeCurrentTask(now: Date) throws -> Bool {
        let summary: TaskCompletionSummary?
        if let database {
            summary = try database.completeCurrentTask(in: &todayTaskState, now: now)
        } else {
            summary = taskEngine.completeCurrentTask(in: &todayTaskState, now: now)
        }

        guard summary != nil else {
            return false
        }

        try startReminderCooldown(now: now)
        try clearReminderSnooze()
        try reloadHistory()
        return true
    }

    func handleTaskNotificationAction(_ action: TaskNotificationAction) {
        do {
            switch action {
            case .completed:
                let completed = try completeCurrentTask(now: Date())
                lastReminderMessage = completed ? "已完成，30 分钟后再提醒。" : "当前没有待完成任务。"
                if completed {
                    syncTeamSnapshot()
                }
            case .remindIn30Minutes:
                try snoozeReminder(duration: 30 * 60, label: "30 分钟后")
            case .remindIn2Hours:
                try snoozeReminder(duration: 2 * 60 * 60, label: "两小时后")
            }
        } catch {
            recordError("处理通知操作失败：\(error.localizedDescription)")
        }
    }

    func switchCurrentTask() {
        do {
            if let database {
                _ = try database.switchTask(in: &todayTaskState)
            } else {
                _ = taskEngine.switchTask(in: &todayTaskState)
            }

            try reloadHistory()
        } catch {
            recordError("切换任务失败：\(error.localizedDescription)")
        }
    }

    func refreshForCurrentDay() {
        do {
            if let database {
                todayTaskState = try database.loadTodayState()
            } else {
                taskEngine.ensureCurrentDay(in: &todayTaskState)
            }

            selectedHistoryDateKey = todayTaskState.dateKey
            try reloadHistory()
            try reloadTeamRankingCache()
        } catch {
            recordError("刷新今日状态失败：\(error.localizedDescription)")
        }
    }

    func clearLocalData() {
        do {
            if let database {
                try database.clearAllData()
                todayTaskState = try database.loadTodayState()
                cooldownStartedAt = try database.loadReminderCooldownStartedAt()
                reminderSnoozedUntil = try database.loadReminderSnoozedUntil()
            } else {
                todayTaskState = taskEngine.makeInitialState()
                cooldownStartedAt = nil
                reminderSnoozedUntil = nil
            }

            selectedHistoryDateKey = todayTaskState.dateKey
            try reloadHistory()
            lastReminderMessage = nil
            lastErrorMessage = nil
            teamProfile = nil
            teamRanking = nil
            teamStatusMessage = nil
        } catch {
            recordError("清除本地数据失败：\(error.localizedDescription)")
        }
    }

    func requestNotificationPermission() {
        notificationService?.requestAuthorization { [weak self] state, error in
            self?.notificationPermissionState = state

            if let error {
                self?.lastReminderMessage = "通知授权失败：\(error.localizedDescription)"
                return
            }

            switch state {
            case .enabled:
                self?.lastReminderMessage = "通知已开启，点模拟可以验证系统通知。"
            case .denied:
                self?.lastReminderMessage = "通知被系统关闭，请点系统打开 HealthyVibe 通知。"
            case .notDetermined:
                self?.lastReminderMessage = "系统没有弹出授权窗口，请点系统手动开启。"
            case .unknown:
                self?.lastReminderMessage = "通知状态未知，请点系统检查权限。"
            }
        }
    }

    func refreshNotificationPermission() {
        notificationService?.refreshAuthorizationStatus { [weak self] state in
            self?.notificationPermissionState = state
        }
    }

    func openNotificationSettings() {
        notificationService?.openNotificationSettings()
    }

    func simulatePromptSubmitted() {
        handlePromptSubmitted(source: "debug", now: Date(), bypassCooldown: true)
    }

    func connectAgent(_ agent: AgentKind) {
        do {
            try hookBridgeManager?.connect(agent)
            refreshAgentStatuses()
            agentStatusMessage = connectionMessage(for: agent)
            lastErrorMessage = nil
        } catch {
            recordError("连接 \(agent.displayName) 失败：\(error.localizedDescription)")
        }
    }

    func disconnectAgent(_ agent: AgentKind) {
        do {
            try hookBridgeManager?.disconnect(agent)
            refreshAgentStatuses()
            agentStatusMessage = "已断开 \(agent.displayName)。"
            lastErrorMessage = nil
        } catch {
            recordError("断开 \(agent.displayName) 失败：\(error.localizedDescription)")
        }
    }

    func testAgentHook(_ agent: AgentKind) {
        do {
            try hookBridgeManager?.sendTestEvent(for: agent)
            try processPendingHookEvents()
            refreshAgentStatuses()
            agentStatusMessage = "本地 hook 脚本可写入事件；Codex 真实触发仍需 /hooks 信任。"
            lastErrorMessage = nil
        } catch {
            recordError("测试 \(agent.displayName) hook 失败：\(error.localizedDescription)")
        }
    }

    func status(for agent: AgentKind) -> AgentConnectionStatus {
        agentConnectionStatuses[agent] ?? .notConnected
    }

    var hasConnectedAgent: Bool {
        AgentKind.allCases.contains { status(for: $0) == .connected }
    }

    var agentHintText: String? {
        if status(for: .codex) == .connected {
            return "Codex 已写入 hooks.json；重启 Codex 后输入 /hooks，信任 HealthyVibe。"
        }

        if status(for: .claude) == .connected {
            return "Claude 已写入 settings.json；重启会话后生效。"
        }

        return nil
    }

    var teamRankText: String? {
        guard
            let teamProfile,
            let teamRanking,
            let rank = teamRanking.rank(for: teamProfile.memberIDHash)
        else {
            return nil
        }

        return "小队排名 \(rank)/\(teamRanking.members.count)"
    }

    func createTeam() {
        saveTeam(code: TeamIdentity.generateTeamCode())
    }

    func joinTeam(code: String) {
        saveTeam(code: code)
    }

    func leaveTeam() {
        do {
            try database?.clearTeamProfile()
            teamProfile = nil
            teamRanking = nil
            teamStatusMessage = nil
        } catch {
            recordError("退出小队失败：\(error.localizedDescription)")
        }
    }

    func syncTeamSnapshot() {
        guard let teamProfile else {
            return
        }

        let snapshot = TeamSnapshot(
            teamCodeHash: teamProfile.teamCodeHash,
            memberIdHash: teamProfile.memberIDHash,
            displayName: teamProfile.displayName,
            date: todayTaskState.dateKey,
            longevityMinutes: todayTaskState.totalLongevityMinutes,
            completedTaskCount: todayTaskState.completedTaskCount,
            updatedAt: Date()
        )

        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            do {
                try await teamRelayClient.postSnapshot(snapshot)
                let ranking = try await teamRelayClient.fetchRanking(
                    teamCodeHash: teamProfile.teamCodeHash,
                    date: snapshot.date
                )
                try database?.saveTeamRankingCache(ranking)
                teamRanking = ranking
                teamStatusMessage = "小队已同步"
            } catch {
                teamStatusMessage = "Relay 暂不可用，本地进度已保存。"
                AppLog.app.error("Team sync failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func historySummary(for dateKey: String) -> DailyHistorySummary? {
        monthSummaries.first { $0.dateKey == dateKey }
    }

    var selectedHistorySummary: DailyHistorySummary? {
        guard let selectedHistoryDateKey else {
            return nil
        }

        return historySummary(for: selectedHistoryDateKey)
    }

    private func reloadHistory() throws {
        if let database {
            monthSummaries = try database.loadMonthSummaries()
            historyOverview = try database.loadHistoryOverview()
        } else {
            monthSummaries = []
            historyOverview = HistoryOverview(
                todayDateKey: todayTaskState.dateKey,
                todayMinutes: todayTaskState.totalLongevityMinutes,
                currentStreakDays: todayTaskState.completedTaskCount > 0 ? 1 : 0,
                totalLongevityMinutes: todayTaskState.totalLongevityMinutes
            )
        }
    }

    private func reloadTeamRankingCache() throws {
        guard let teamProfile else {
            teamRanking = nil
            return
        }

        teamRanking = try database?.loadTeamRankingCache(
            teamCodeHash: teamProfile.teamCodeHash,
            date: todayTaskState.dateKey
        )
    }

    private func saveTeam(code: String) {
        let normalizedCode = TeamIdentity.normalizeTeamCode(code)
        guard TeamIdentity.isValidTeamCode(normalizedCode) else {
            teamStatusMessage = "请输入 6 位数字小队码。"
            return
        }

        let memberID = teamProfile?.memberID.isEmpty == false ? teamProfile?.memberID : UUID().uuidString
        let profile = TeamIdentity.makeProfile(
            teamCode: normalizedCode,
            memberID: memberID ?? UUID().uuidString,
            displayName: teamProfile?.displayName
        )

        do {
            try database?.saveTeamProfile(profile)
            teamProfile = profile
            try reloadTeamRankingCache()
            teamStatusMessage = "已加入小队 \(profile.teamCode)"
            syncTeamSnapshot()
        } catch {
            recordError("保存小队失败：\(error.localizedDescription)")
        }
    }

    private func recordError(_ message: String) {
        lastErrorMessage = message
        AppLog.app.error("\(message, privacy: .public)")
    }

    private func refreshAgentStatuses() {
        agentConnectionStatuses = hookBridgeManager?.statuses() ?? [:]
    }

    private func startHookEventPolling() {
        hookEventPollTimer?.invalidate()
        hookEventPollTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                do {
                    try self?.processPendingHookEvents()
                } catch {
                    self?.recordError("读取 hook 事件失败：\(error.localizedDescription)")
                }
            }
        }
    }

    private func processPendingHookEvents() throws {
        guard let hookBridgeManager else {
            return
        }

        let events = try hookBridgeManager.readPendingEvents()
        for event in events where event.event == "prompt_submitted" {
            handlePromptSubmitted(source: event.source, now: event.receivedAt)
        }
    }

    private func handlePromptSubmitted(
        source: String,
        now: Date,
        bypassCooldown: Bool = false
    ) {
        activeTimeTracker?.recordHookEvent()

        do {
            try database?.recordHookEvent(
                source: source,
                event: "prompt_submitted",
                receivedAt: now,
                processedAt: now
            )
            try deliverReminder(
                source: source,
                reason: .promptSubmitted,
                now: now,
                bypassCooldown: bypassCooldown
            )
        } catch {
            recordError("处理 prompt 事件失败：\(error.localizedDescription)")
        }
    }

    private func handleFallbackReminder() {
        do {
            try deliverReminder(source: "fallback", reason: .activeFallback, now: Date())
        } catch {
            recordError("处理兜底提醒失败：\(error.localizedDescription)")
        }
    }

    private func deliverReminder(
        source: String,
        reason: ReminderReason,
        now: Date,
        bypassCooldown: Bool = false
    ) throws {
        try refreshStateForReminder(now: now)

        if !bypassCooldown, let snoozedMessage = try activeSnoozeMessage(now: now) {
            lastReminderMessage = snoozedMessage
            return
        }

        guard bypassCooldown || shouldDeliverReminder(now: now) else {
            lastReminderMessage = cooldownMessage(now: now)
            return
        }

        guard !todayTaskState.allCompleted else {
            lastReminderMessage = "今日任务池已完成，不再下发新任务。"
            return
        }

        let item: DailyTaskItem?
        if let currentTask = todayTaskState.currentTask {
            item = currentTask
        } else if let database {
            item = try database.deliverTask(in: &todayTaskState, source: source, now: now)
        } else {
            item = taskEngine.deliverTask(in: &todayTaskState, now: now)
        }

        guard let item else {
            lastReminderMessage = "今天没有可下发的任务了。"
            return
        }

        try reloadHistory()

        let body = notificationBody(source: source, item: item, reason: reason)
        lastReminderMessage = body

        if notificationPermissionState == .enabled {
            notificationService?.sendTaskNotification(title: "Vibe延寿指南", body: body) { [weak self] error in
                if let error {
                    self?.lastReminderMessage = "\(body)｜通知发送失败：\(error.localizedDescription)"
                } else {
                    self?.lastReminderMessage = "\(body)｜系统通知已发送。"
                }
            }
        } else {
            lastReminderMessage = "通知未开启：\(body)"
        }
    }

    private func connectionMessage(for agent: AgentKind) -> String {
        switch agent {
        case .claude:
            "Claude 已写入 settings.json；重启会话后生效。"
        case .codex:
            "Codex 已写入 hooks.json；重启 Codex 后输入 /hooks，信任 HealthyVibe。"
        }
    }

    private func refreshStateForReminder(now: Date) throws {
        if let database {
            todayTaskState = try database.loadTodayState(now: now)
        } else {
            taskEngine.ensureCurrentDay(in: &todayTaskState, now: now)
        }
    }

    private func shouldDeliverReminder(now: Date) -> Bool {
        guard let cooldownStartedAt else {
            return true
        }

        return now.timeIntervalSince(cooldownStartedAt) >= reminderCooldown
    }

    private func cooldownMessage(now: Date) -> String {
        guard let cooldownStartedAt else {
            return "hook 已收到，暂不下发新任务。"
        }

        let remainingSeconds = max(0, reminderCooldown - now.timeIntervalSince(cooldownStartedAt))
        let remainingMinutes = max(1, Int(ceil(remainingSeconds / 60)))
        return "hook 已收到，完成冷却剩余约 \(remainingMinutes) 分钟。"
    }

    private func activeSnoozeMessage(now: Date) throws -> String? {
        guard let snoozedUntil = reminderSnoozedUntil else {
            return nil
        }

        if now >= snoozedUntil {
            try clearReminderSnooze()
            return nil
        }

        let remainingSeconds = max(0, snoozedUntil.timeIntervalSince(now))
        let remainingMinutes = max(1, Int(ceil(remainingSeconds / 60)))
        return "hook 已收到，稍后提醒剩余约 \(remainingMinutes) 分钟。"
    }

    private func startReminderCooldown(now: Date) throws {
        cooldownStartedAt = now
        try database?.saveReminderCooldownStartedAt(now)
    }

    private func clearReminderSnooze() throws {
        reminderSnoozedUntil = nil
        try database?.clearReminderSnoozedUntil()
        notificationService?.cancelSnoozedTaskNotification()
    }

    private func snoozeReminder(duration: TimeInterval, label: String) throws {
        let now = Date()
        try refreshStateForReminder(now: now)

        guard let item = todayTaskState.currentTask else {
            lastReminderMessage = "当前没有待稍后提醒的任务。"
            return
        }

        let snoozedUntil = now.addingTimeInterval(duration)
        reminderSnoozedUntil = snoozedUntil
        try database?.saveReminderSnoozedUntil(snoozedUntil)

        let body = notificationBody(source: "snooze", item: item, reason: .snoozed)
        lastReminderMessage = "已改到\(label)提醒。"

        if notificationPermissionState == .enabled {
            notificationService?.sendTaskNotification(
                title: "Vibe延寿指南",
                body: body,
                delay: duration
            ) { [weak self] error in
                if let error {
                    self?.lastReminderMessage = "稍后提醒设置失败：\(error.localizedDescription)"
                } else {
                    self?.lastReminderMessage = "已改到\(label)提醒。"
                }
            }
        }
    }

    private func notificationBody(
        source: String,
        item: DailyTaskItem,
        reason: ReminderReason
    ) -> String {
        switch reason {
        case .promptSubmitted:
            let agentName = source == "debug" ? "Agent" : source.capitalized
            return "\(agentName) 开始干活了。你先\(item.template.title)，别盯着进度条等。"
        case .activeFallback:
            return "这一小时没等到新的 agent，也该给身体发个 keepalive 了。先\(item.template.title)。"
        case .snoozed:
            return "稍后提醒到了。先\(item.template.title)，给身体一点缓存时间。"
        }
    }
}

enum SetupStatus {
    case initializing
    case ready
    case failed
}

private enum ReminderReason {
    case promptSubmitted
    case activeFallback
    case snoozed
}
