import Foundation

public struct DailyHistorySummary: Codable, Equatable, Identifiable {
    public var id: String { dateKey }

    public let dateKey: String
    public let longevityMinutes: Int
    public let completedTaskCount: Int
    public let targetMinutes: Int

    public init(
        dateKey: String,
        longevityMinutes: Int,
        completedTaskCount: Int,
        targetMinutes: Int
    ) {
        self.dateKey = dateKey
        self.longevityMinutes = longevityMinutes
        self.completedTaskCount = completedTaskCount
        self.targetMinutes = targetMinutes
    }

    public var hasRecord: Bool {
        longevityMinutes > 0 || completedTaskCount > 0
    }

    public var reachedGoal: Bool {
        targetMinutes > 0 && longevityMinutes >= targetMinutes
    }
}

public struct HistoryOverview: Codable, Equatable {
    public let todayDateKey: String
    public let todayMinutes: Int
    public let currentStreakDays: Int
    public let totalLongevityMinutes: Int

    public init(
        todayDateKey: String,
        todayMinutes: Int,
        currentStreakDays: Int,
        totalLongevityMinutes: Int
    ) {
        self.todayDateKey = todayDateKey
        self.todayMinutes = todayMinutes
        self.currentStreakDays = currentStreakDays
        self.totalLongevityMinutes = totalLongevityMinutes
    }

    public static func empty(todayDateKey: String = "") -> HistoryOverview {
        HistoryOverview(
            todayDateKey: todayDateKey,
            todayMinutes: 0,
            currentStreakDays: 0,
            totalLongevityMinutes: 0
        )
    }
}
