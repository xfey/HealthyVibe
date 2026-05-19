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
            "Unknown"
        case .notDetermined:
            "Not Requested"
        case .enabled:
            "Enabled"
        case .denied:
            "Disabled"
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
