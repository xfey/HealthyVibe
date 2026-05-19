import Foundation
import HealthyVibeCore
import HealthyVibeStorage

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedPage: AppPage = .today
    @Published private(set) var setupStatus: SetupStatus = .initializing
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var todayTaskState: TodayTaskState
    @Published private(set) var monthSummaries: [DailyHistorySummary] = []
    @Published private(set) var historyOverview: HistoryOverview
    @Published var selectedHistoryDateKey: String?

    let paths: AppPaths
    private let taskEngine: TaskEngine
    private var database: AppDatabase?

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
            todayTaskState = try database.loadTodayState()
            selectedHistoryDateKey = todayTaskState.dateKey
            try reloadHistory()
            setupStatus = .ready
            lastErrorMessage = nil
            AppLog.app.info("HealthyVibe bootstrapped successfully.")
        } catch {
            setupStatus = .failed
            lastErrorMessage = "初始化本地目录失败，请检查 Application Support 权限。"
            AppLog.app.error("Bootstrap failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    var todayProgressText: String {
        "今日 \(todayTaskState.totalLongevityMinutes) / \(todayTaskState.targetMinutes) 分钟"
    }

    var canDeliverTask: Bool {
        !todayTaskState.remainingItems.isEmpty
    }

    var canSwitchTask: Bool {
        todayTaskState.remainingItems.count > 1 || todayTaskState.currentTask != nil
    }

    func deliverManualTask() {
        do {
            if let database {
                _ = try database.deliverTask(in: &todayTaskState, source: "manual")
            } else {
                _ = taskEngine.deliverTask(in: &todayTaskState)
            }

            try reloadHistory()
        } catch {
            recordError("下发任务失败：\(error.localizedDescription)")
        }
    }

    func completeCurrentTask() {
        do {
            if let database {
                _ = try database.completeCurrentTask(in: &todayTaskState)
            } else {
                _ = taskEngine.completeCurrentTask(in: &todayTaskState)
            }

            try reloadHistory()
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
        } catch {
            recordError("刷新今日状态失败：\(error.localizedDescription)")
        }
    }

    func clearLocalData() {
        do {
            if let database {
                try database.clearAllData()
                todayTaskState = try database.loadTodayState()
            } else {
                todayTaskState = taskEngine.makeInitialState()
            }

            selectedHistoryDateKey = todayTaskState.dateKey
            try reloadHistory()
            lastErrorMessage = nil
        } catch {
            recordError("清除本地数据失败：\(error.localizedDescription)")
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

    private func recordError(_ message: String) {
        lastErrorMessage = message
        AppLog.app.error("\(message, privacy: .public)")
    }
}

enum SetupStatus {
    case initializing
    case ready
    case failed
}
