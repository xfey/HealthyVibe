import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedPage: AppPage = .today
    @Published private(set) var setupStatus: SetupStatus = .initializing
    @Published private(set) var lastErrorMessage: String?

    let paths: AppPaths
    private let databaseService: DatabaseService

    init(paths: AppPaths = AppPaths()) {
        self.paths = paths
        self.databaseService = PlaceholderDatabaseService(paths: paths)
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
}

enum SetupStatus {
    case initializing
    case ready
    case failed
}
