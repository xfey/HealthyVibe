import Foundation

enum AppPage: String, CaseIterable, Identifiable {
    case today
    case team
    case calendar
    case settings
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today:
            "今日任务"
        case .team:
            "小队"
        case .calendar:
            "日历"
        case .settings:
            "设置"
        case .about:
            "关于"
        }
    }

    var systemImageName: String {
        switch self {
        case .today:
            "bolt.heart"
        case .team:
            "person.2"
        case .calendar:
            "calendar"
        case .settings:
            "slider.horizontal.3"
        case .about:
            "info.circle"
        }
    }
}
