import Foundation

enum AppPage: String, CaseIterable, Identifiable {
    case today
    case calendar
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today:
            "今日任务"
        case .calendar:
            "日历"
        case .settings:
            "设置"
        }
    }

    var systemImageName: String {
        switch self {
        case .today:
            "bolt.heart"
        case .calendar:
            "calendar"
        case .settings:
            "slider.horizontal.3"
        }
    }
}
