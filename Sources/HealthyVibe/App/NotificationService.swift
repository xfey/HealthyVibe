import AppKit
import Foundation
import UserNotifications

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    var onNotificationActivated: (() -> Void)?

    private let center: UNUserNotificationCenter

    override init() {
        self.center = .current()
        super.init()
        center.delegate = self
    }

    func refreshAuthorizationStatus(_ completion: @escaping (NotificationPermissionState) -> Void) {
        center.getNotificationSettings { settings in
            let state = NotificationPermissionState.from(settings.authorizationStatus)
            DispatchQueue.main.async {
                completion(state)
            }
        }
    }

    func requestAuthorization(_ completion: @escaping (NotificationPermissionState) -> Void) {
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] _, _ in
            self?.refreshAuthorizationStatus(completion)
        }
    }

    func sendTaskNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["healthyvibe": "task-reminder"]

        let request = UNNotificationRequest(
            identifier: "healthyvibe.task.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        center.add(request)
    }

    func openNotificationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.onNotificationActivated?()
            completionHandler()
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
