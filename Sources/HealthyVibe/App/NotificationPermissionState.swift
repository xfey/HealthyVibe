import Foundation
import UserNotifications

enum NotificationPermissionState: Equatable {
    case unknown
    case notDetermined
    case enabled
    case denied

    var displayText: String {
        switch self {
        case .unknown:
            "未知"
        case .notDetermined:
            "未请求"
        case .enabled:
            "已开启"
        case .denied:
            "已关闭"
        }
    }

    static func from(_ status: UNAuthorizationStatus) -> NotificationPermissionState {
        switch status {
        case .notDetermined:
            .notDetermined
        case .authorized, .provisional:
            .enabled
        case .denied:
            .denied
        @unknown default:
            .unknown
        }
    }
}
