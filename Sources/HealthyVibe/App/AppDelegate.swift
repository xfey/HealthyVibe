import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appModel = AppModel()
    private lazy var menuBarController = MenuBarController(appModel: appModel)
    private lazy var notificationService = NotificationService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        appModel.bootstrap()
        menuBarController.install()
        notificationService.onNotificationActivated = { [weak self] in
            self?.menuBarController.show(page: .today)
        }
        notificationService.onTaskNotificationAction = { [weak self] action in
            self?.appModel.handleTaskNotificationAction(action)
        }
        appModel.attachNotificationService(notificationService)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
