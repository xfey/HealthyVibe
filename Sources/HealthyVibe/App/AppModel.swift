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
    private var lastReminderAt: Date?
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
            lastReminderAt = try database.loadLastReminderDate()
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
            if let database {
                _ = try database.completeCurrentTask(in: &todayTaskState)
            } else {
                _ = taskEngine.completeCurrentTask(in: &todayTaskState)
            }

            try reloadHistory()
            syncTeamSnapshot()
        } catch {
            recordError("完成任务失败：\(error.localizedDescription)")
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
                lastReminderAt = try database.loadLastReminderDate()
            } else {
                todayTaskState = taskEngine.makeInitialState()
                lastReminderAt = nil
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
        notificationService?.requestAuthorization { [weak self] state in
            self?.notificationPermissionState = state
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
        handlePromptSubmitted(source: "debug", now: Date())
    }

    func connectAgent(_ agent: AgentKind) {
        do {
            try hookBridgeManager?.connect(agent)
            refreshAgentStatuses()
            lastErrorMessage = nil
        } catch {
            recordError("连接 \(agent.displayName) 失败：\(error.localizedDescription)")
        }
    }

    func disconnectAgent(_ agent: AgentKind) {
        do {
            try hookBridgeManager?.disconnect(agent)
            refreshAgentStatuses()
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
        guard normalizedCode.replacingOccurrences(of: "-", with: "").count >= 8 else {
            teamStatusMessage = "请输入有效的小队码。"
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

    private func handlePromptSubmitted(source: String, now: Date) {
        activeTimeTracker?.recordHookEvent()

        do {
            try database?.recordHookEvent(
                source: source,
                event: "prompt_submitted",
                receivedAt: now,
                processedAt: now
            )
            try deliverReminder(source: source, reason: .promptSubmitted, now: now)
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
        now: Date
    ) throws {
        try refreshStateForReminder(now: now)

        guard shouldDeliverReminder(now: now) else {
            lastReminderMessage = "冷却中：30 分钟内不会重复下发任务。"
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

        try database?.saveLastReminderDate(now)
        lastReminderAt = now
        try reloadHistory()

        let body = notificationBody(source: source, item: item, reason: reason)
        lastReminderMessage = body

        if notificationPermissionState == .enabled {
            notificationService?.sendTaskNotification(title: "Vibe延寿指南", body: body)
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
        guard let lastReminderAt else {
            return true
        }

        return now.timeIntervalSince(lastReminderAt) >= reminderCooldown
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
}
