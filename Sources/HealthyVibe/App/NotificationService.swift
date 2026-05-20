import AppKit
import Foundation
import UserNotifications

enum TaskNotificationAction {
    case completed
    case remindIn30Minutes
    case remindIn2Hours
}

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    var onNotificationActivated: (() -> Void)?
    var onTaskNotificationAction: ((TaskNotificationAction) -> Void)?

    private let center: UNUserNotificationCenter
    private let taskCategoryIdentifier = "healthyvibe.task"
    private let completedActionIdentifier = "healthyvibe.task.completed"
    private let remindIn30MinutesActionIdentifier = "healthyvibe.task.remind-30"
    private let remindIn2HoursActionIdentifier = "healthyvibe.task.remind-120"
    private let snoozedRequestIdentifier = "healthyvibe.task.snoozed"

    override init() {
        self.center = .current()
        super.init()
        center.delegate = self
        registerNotificationActions()
    }

    func refreshAuthorizationStatus(_ completion: @escaping (NotificationPermissionState) -> Void) {
        center.getNotificationSettings { settings in
            let state = NotificationPermissionState.from(settings.authorizationStatus)
            DispatchQueue.main.async {
                completion(state)
            }
        }
    }

    func requestAuthorization(_ completion: @escaping (NotificationPermissionState, Error?) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            NSApp.activate(ignoringOtherApps: true)
            center.requestAuthorization(options: [.alert, .sound]) { [weak self] _, error in
                self?.refreshAuthorizationStatus { state in
                    completion(state, error)
                }
            }
        }
    }

    func sendTaskNotification(
        title: String,
        body: String,
        delay: TimeInterval? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["healthyvibe": "task-reminder"]
        content.categoryIdentifier = taskCategoryIdentifier

        let trigger: UNNotificationTrigger?
        let identifier: String
        if let delay, delay > 0 {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            identifier = snoozedRequestIdentifier
            center.removePendingNotificationRequests(withIdentifiers: [snoozedRequestIdentifier])
        } else {
            trigger = nil
            identifier = "healthyvibe.task.\(UUID().uuidString)"
        }

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            DispatchQueue.main.async {
                completion?(error)
            }
        }
    }

    func openNotificationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    func cancelSnoozedTaskNotification() {
        center.removePendingNotificationRequests(withIdentifiers: [snoozedRequestIdentifier])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                completionHandler()
                return
            }

            switch response.actionIdentifier {
            case completedActionIdentifier:
                onTaskNotificationAction?(.completed)
            case remindIn30MinutesActionIdentifier:
                onTaskNotificationAction?(.remindIn30Minutes)
            case remindIn2HoursActionIdentifier:
                onTaskNotificationAction?(.remindIn2Hours)
            case UNNotificationDefaultActionIdentifier:
                onNotificationActivated?()
            default:
                break
            }

            completionHandler()
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    private func registerNotificationActions() {
        let completedAction = UNNotificationAction(
            identifier: completedActionIdentifier,
            title: "已完成",
            options: []
        )
        let remindIn30MinutesAction = UNNotificationAction(
            identifier: remindIn30MinutesActionIdentifier,
            title: "30分钟后提醒",
            options: []
        )
        let remindIn2HoursAction = UNNotificationAction(
            identifier: remindIn2HoursActionIdentifier,
            title: "两小时后提醒",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: taskCategoryIdentifier,
            actions: [
                completedAction,
                remindIn30MinutesAction,
                remindIn2HoursAction
            ],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        center.setNotificationCategories([category])
    }
}
