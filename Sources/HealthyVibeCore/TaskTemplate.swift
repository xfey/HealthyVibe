import Foundation

public struct TaskTemplate: Codable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let maxDailyCount: Int
    public let rewardMinutes: Int
    public let rewardSuffix: String

    public init(
        id: String,
        title: String,
        subtitle: String,
        maxDailyCount: Int,
        rewardMinutes: Int,
        rewardSuffix: String
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.maxDailyCount = maxDailyCount
        self.rewardMinutes = rewardMinutes
        self.rewardSuffix = rewardSuffix
    }
}

public extension TaskTemplate {
    static let defaultTemplates: [TaskTemplate] = [
        TaskTemplate(
            id: "water",
            title: "喝一杯水",
            subtitle: "给缓存里的你也补点水",
            maxDailyCount: 8,
            rewardMinutes: 2,
            rewardSuffix: "可以多听一首歌的前奏"
        ),
        TaskTemplate(
            id: "look-away",
            title: "远眺 20 秒",
            subtitle: "让眼睛从 diff 里撤退一下",
            maxDailyCount: 6,
            rewardMinutes: 2,
            rewardSuffix: "可以多看一页喜欢的书"
        ),
        TaskTemplate(
            id: "stand",
            title: "起身活动 30 秒",
            subtitle: "把身体从椅子缓存里释放出来",
            maxDailyCount: 3,
            rewardMinutes: 4,
            rewardSuffix: "可以认真伸个懒腰"
        ),
        TaskTemplate(
            id: "shoulder-neck",
            title: "肩颈活动 30 秒",
            subtitle: "给脖子做一次轻量 refactor",
            maxDailyCount: 3,
            rewardMinutes: 3,
            rewardSuffix: "可以多走到窗边看一眼"
        ),
        TaskTemplate(
            id: "wrist",
            title: "手腕活动 15 秒",
            subtitle: "让快捷键选手先休息一下",
            maxDailyCount: 3,
            rewardMinutes: 2,
            rewardSuffix: "可以多泡一杯热饮"
        ),
        TaskTemplate(
            id: "breath",
            title: "深呼吸 5 次",
            subtitle: "给大脑降一点风扇转速",
            maxDailyCount: 3,
            rewardMinutes: 2,
            rewardSuffix: "可以多安静发会儿呆"
        )
    ]
}
