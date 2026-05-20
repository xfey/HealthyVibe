import Foundation

public enum LongevityCopy {
    public static func rewardLine(for item: DailyTaskItem) -> String {
        "延寿 +\(item.template.rewardMinutes) 分钟，\(rewardSuffix(for: item))"
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
        totalMilestones
            .first { minutes >= $0.minutes }?
            .suffix ?? "先从一次微休息开始"
    }

    private static func rewardSuffix(for item: DailyTaskItem) -> String {
        let options = taskRewardSuffixes[item.template.id] ?? [item.template.rewardSuffix]
        guard !options.isEmpty else {
            return item.template.rewardSuffix
        }

        return options[item.completedCount % options.count]
    }
}

private struct LongevityMilestone {
    let minutes: Int
    let suffix: String
}

private let totalMilestones: [LongevityMilestone] = [
    LongevityMilestone(minutes: 1440, suffix: "可以给自己放一个完整周末"),
    LongevityMilestone(minutes: 1080, suffix: "可以坐一趟夜车去看海"),
    LongevityMilestone(minutes: 900, suffix: "可以慢慢逛完一座城市公园"),
    LongevityMilestone(minutes: 720, suffix: "可以睡到自然醒再吃早午餐"),
    LongevityMilestone(minutes: 600, suffix: "可以完成一次短途一日游"),
    LongevityMilestone(minutes: 480, suffix: "可以坐一趟慢火车去海边"),
    LongevityMilestone(minutes: 420, suffix: "可以做一桌朋友聚餐"),
    LongevityMilestone(minutes: 360, suffix: "可以打完一场桌游局"),
    LongevityMilestone(minutes: 300, suffix: "可以整理一下午房间再点奶茶"),
    LongevityMilestone(minutes: 270, suffix: "可以看完一场演唱会录像"),
    LongevityMilestone(minutes: 240, suffix: "可以烤一盘饼干等它放凉"),
    LongevityMilestone(minutes: 210, suffix: "可以逛完一个博物馆展厅"),
    LongevityMilestone(minutes: 180, suffix: "可以煲一锅汤再慢慢喝"),
    LongevityMilestone(minutes: 165, suffix: "可以看完一场球赛的下半场"),
    LongevityMilestone(minutes: 150, suffix: "可以拼完一幅小拼图"),
    LongevityMilestone(minutes: 135, suffix: "可以做一次完整家务清单"),
    LongevityMilestone(minutes: 120, suffix: "可以看完一场电影再吃夜宵"),
    LongevityMilestone(minutes: 110, suffix: "可以骑车去河边吹风"),
    LongevityMilestone(minutes: 100, suffix: "可以做一顿像样的晚餐"),
    LongevityMilestone(minutes: 90, suffix: "可以认真泡一次澡"),
    LongevityMilestone(minutes: 80, suffix: "可以读完一本《小王子》"),
    LongevityMilestone(minutes: 70, suffix: "可以逛一趟花市"),
    LongevityMilestone(minutes: 60, suffix: "可以煮一锅热粥"),
    LongevityMilestone(minutes: 50, suffix: "可以买菜回家再洗好水果"),
    LongevityMilestone(minutes: 45, suffix: "可以做一份番茄肉酱面"),
    LongevityMilestone(minutes: 40, suffix: "可以游泳 40 分钟，约消耗 300 千卡"),
    LongevityMilestone(minutes: 35, suffix: "可以烤一只小红薯"),
    LongevityMilestone(minutes: 30, suffix: "可以去咖啡店坐到第一首歌结束"),
    LongevityMilestone(minutes: 25, suffix: "可以把晚饭的米饭焖好"),
    LongevityMilestone(minutes: 20, suffix: "可以下楼买一束花"),
    LongevityMilestone(minutes: 18, suffix: "可以煮一碗云吞面"),
    LongevityMilestone(minutes: 16, suffix: "可以给房间换一只香薰"),
    LongevityMilestone(minutes: 14, suffix: "可以洗一盘草莓"),
    LongevityMilestone(minutes: 12, suffix: "可以给朋友发一条语音"),
    LongevityMilestone(minutes: 10, suffix: "可以下楼吃一个冰激凌"),
    LongevityMilestone(minutes: 8, suffix: "可以冲一杯热可可"),
    LongevityMilestone(minutes: 6, suffix: "可以剥好一颗橙子"),
    LongevityMilestone(minutes: 5, suffix: "可以听完一首喜欢的歌"),
    LongevityMilestone(minutes: 4, suffix: "可以给猫粮碗加满"),
    LongevityMilestone(minutes: 3, suffix: "可以擦干净一张桌子"),
    LongevityMilestone(minutes: 2, suffix: "可以切两片柠檬泡水"),
    LongevityMilestone(minutes: 1, suffix: "可以给自己倒一杯水")
]

private let taskRewardSuffixes: [String: [String]] = [
    "water": [
        "可以剥一颗橘子",
        "可以切两片柠檬泡水",
        "可以把水壶重新烧开",
        "可以给杯子加一片薄荷",
        "可以洗一个苹果",
        "可以把冰箱里的饮料摆整齐",
        "可以给自己倒一杯气泡水",
        "可以把早餐燕麦泡好"
    ],
    "look-away": [
        "可以咬一口冰西瓜",
        "可以挑一张明信片",
        "可以看完一格漫画",
        "可以闻一下新鲜面包",
        "可以给桌面换一张照片",
        "可以翻到书签那一页",
        "可以给相册删掉一张废片",
        "可以把水果盘端出来"
    ],
    "stand": [
        "可以去楼下取个快递",
        "可以把垃圾袋扎好",
        "可以给洗衣机按下开始",
        "可以把鞋柜整理一层",
        "可以去便利店买一盒酸奶",
        "可以把阳台门打开透气"
    ],
    "shoulder-neck": [
        "可以煎一个太阳蛋",
        "可以切一把小葱",
        "可以给汤面撒点胡椒",
        "可以把咖啡豆称好",
        "可以洗好一个便当盒",
        "可以把晚饭菜单想好"
    ],
    "wrist": [
        "可以给绿植浇点水",
        "可以把钥匙放回玄关",
        "可以给手机换上充电线",
        "可以撕掉一张便利贴",
        "可以把耳机放回盒子",
        "可以给手边零食封口"
    ],
    "breath": [
        "可以选一首晚饭歌",
        "可以点一支无火香薰",
        "可以给日历画一个小勾",
        "可以把明天早餐想好",
        "可以把外卖备注写完整",
        "可以给自己留一句晚安"
    ]
]
