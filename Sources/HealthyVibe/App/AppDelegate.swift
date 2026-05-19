import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appModel = AppModel()
    private lazy var menuBarController = MenuBarController(appModel: appModel)

    func applicationDidFinishLaunching(_ notification: Notification) {
        appModel.bootstrap()
        menuBarController.install()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
