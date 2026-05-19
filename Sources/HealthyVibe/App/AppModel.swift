import Foundation
import HealthyVibeCore

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedPage: AppPage = .today
    @Published private(set) var setupStatus: SetupStatus = .initializing
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var todayTaskState: TodayTaskState

    let paths: AppPaths
    private let databaseService: DatabaseService
    private let taskEngine: TaskEngine

    init(paths: AppPaths = AppPaths()) {
        let taskEngine = TaskEngine()
        self.paths = paths
        self.databaseService = PlaceholderDatabaseService(paths: paths)
        self.taskEngine = taskEngine
        self.todayTaskState = taskEngine.makeInitialState()
    }

    func bootstrap() {
        do {
            try paths.ensureCreated()
            try databaseService.bootstrap()
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
        _ = taskEngine.deliverTask(in: &todayTaskState)
    }

    func completeCurrentTask() {
        _ = taskEngine.completeCurrentTask(in: &todayTaskState)
    }

    func switchCurrentTask() {
        _ = taskEngine.switchTask(in: &todayTaskState)
    }
}

enum SetupStatus {
    case initializing
    case ready
    case failed
}
