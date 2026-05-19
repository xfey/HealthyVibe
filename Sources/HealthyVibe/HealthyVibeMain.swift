import AppKit

@MainActor
private var retainedAppDelegate: AppDelegate?

@main
struct HealthyVibeMain {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()

        retainedAppDelegate = delegate
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        application.run()
    }
}
