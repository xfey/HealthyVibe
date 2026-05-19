import Foundation

public enum LongevityCopy {
    public static func rewardLine(for item: DailyTaskItem) -> String {
        "延寿 +\(item.template.rewardMinutes) 分钟，\(item.template.rewardSuffix)"
    }

    public static func completionLine(for summary: TaskCompletionSummary) -> String {
        "本次延寿 +\(summary.rewardMinutes) 分钟，\(suffix(forTotalMinutes: summary.totalLongevityMinutes))"
    }

    public static func totalLine(forTotalMinutes minutes: Int) -> String {
        "累计延寿 \(formattedDuration(minutes))，\(suffix(forTotalMinutes: minutes))"
    }

    public static func formattedDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60

            if remainingMinutes == 0 {
                return "\(hours) 小时"
            }

            return "\(hours) 小时 \(remainingMinutes) 分钟"
        }

        return "\(minutes) 分钟"
    }

    public static func suffix(forTotalMinutes minutes: Int) -> String {
        switch minutes {
        case 480...:
            "可以睡一个完整觉"
        case 120...:
            "可以多看一部电影"
        case 30...:
            "可以多散一次步"
        case 10...:
            "可以慢慢喝完一杯咖啡"
        case 1...:
            "可以认真伸个懒腰"
        default:
            "先从一次微休息开始"
        }
    }
}
