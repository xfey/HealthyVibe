import Foundation

public struct DailyTaskItem: Codable, Equatable, Identifiable {
    public let template: TaskTemplate
    public var completedCount: Int

    public var id: String { template.id }

    public var remainingCount: Int {
        max(0, template.maxDailyCount - completedCount)
    }

    public var isDepleted: Bool {
        remainingCount == 0
    }

    public init(template: TaskTemplate, completedCount: Int = 0) {
        self.template = template
        self.completedCount = min(max(0, completedCount), template.maxDailyCount)
    }
}

public struct TaskCompletionSummary: Codable, Equatable {
    public let templateID: String
    public let title: String
    public let rewardMinutes: Int
    public let totalLongevityMinutes: Int
    public let completedAt: Date

    public init(
        templateID: String,
        title: String,
        rewardMinutes: Int,
        totalLongevityMinutes: Int,
        completedAt: Date
    ) {
        self.templateID = templateID
        self.title = title
        self.rewardMinutes = rewardMinutes
        self.totalLongevityMinutes = totalLongevityMinutes
        self.completedAt = completedAt
    }
}

public enum TaskCardStatus: Equatable {
    case waiting
    case pending(DailyTaskItem)
    case completed(TaskCompletionSummary)
    case allCompleted
}

public struct TodayTaskState: Codable, Equatable {
    public var dateKey: String
    public var items: [DailyTaskItem]
    public var currentTaskID: String?
    public var lastCompletion: TaskCompletionSummary?
    public var targetMinutes: Int

    public init(
        dateKey: String,
        items: [DailyTaskItem],
        currentTaskID: String? = nil,
        lastCompletion: TaskCompletionSummary? = nil,
        targetMinutes: Int = 30
    ) {
        self.dateKey = dateKey
        self.items = items
        self.currentTaskID = currentTaskID
        self.lastCompletion = lastCompletion
        self.targetMinutes = targetMinutes
    }

    public var currentTask: DailyTaskItem? {
        guard let currentTaskID else {
            return nil
        }

        return items.first { $0.id == currentTaskID && !$0.isDepleted }
    }

    public var remainingItems: [DailyTaskItem] {
        items.filter { !$0.isDepleted }
    }

    public var allCompleted: Bool {
        !items.isEmpty && items.allSatisfy(\.isDepleted)
    }

    public var totalLongevityMinutes: Int {
        items.reduce(0) { total, item in
            total + item.completedCount * item.template.rewardMinutes
        }
    }

    public var completedTaskCount: Int {
        items.reduce(0) { $0 + $1.completedCount }
    }

    public var progressFraction: Double {
        guard targetMinutes > 0 else {
            return 0
        }

        return min(1, Double(totalLongevityMinutes) / Double(targetMinutes))
    }

    public var cardStatus: TaskCardStatus {
        if let currentTask {
            return .pending(currentTask)
        }

        if allCompleted {
            return .allCompleted
        }

        if let lastCompletion {
            return .completed(lastCompletion)
        }

        return .waiting
    }
}
