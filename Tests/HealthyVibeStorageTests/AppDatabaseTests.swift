import Foundation
import XCTest
import HealthyVibeCore
@testable import HealthyVibeStorage

final class AppDatabaseTests: XCTestCase {
    func testMigratesAllRoadmapTables() throws {
        let database = try makeDatabase()

        let tables = try database.debugTableNames()

        XCTAssertTrue(tables.isSuperset(of: [
            "task_templates",
            "daily_task_plan",
            "task_deliveries",
            "task_completions",
            "daily_stats",
            "hook_events",
            "team_profile",
            "team_snapshots_cache",
            "app_settings"
        ]))
    }

    func testPersistsTodayTaskStateAcrossDatabaseReopen() throws {
        let (url, cleanup) = makeTemporaryDatabaseURL()
        defer { cleanup() }

        do {
            let database = try makeDatabase(path: url.path)
            var state = try database.loadTodayState(now: fixedDate(dayOffset: 0))

            try database.deliverTask(in: &state, now: fixedDate(dayOffset: 0))
            try database.completeCurrentTask(in: &state, now: fixedDate(dayOffset: 0))
            XCTAssertEqual(state.totalLongevityMinutes, 2)
        }

        do {
            let reopened = try makeDatabase(path: url.path)
            let state = try reopened.loadTodayState(now: fixedDate(dayOffset: 0))

            XCTAssertEqual(state.totalLongevityMinutes, 2)
            XCTAssertEqual(state.completedTaskCount, 1)
            XCTAssertNil(state.currentTask)

            if case .completed(let summary) = state.cardStatus {
                XCTAssertEqual(summary.rewardMinutes, 2)
            } else {
                XCTFail("Expected the latest completion state to survive a reopen.")
            }
        }
    }

    func testPendingDeliverySurvivesDatabaseReopen() throws {
        let (url, cleanup) = makeTemporaryDatabaseURL()
        defer { cleanup() }

        do {
            let database = try makeDatabase(path: url.path)
            var state = try database.loadTodayState(now: fixedDate(dayOffset: 0))
            try database.deliverTask(in: &state, now: fixedDate(dayOffset: 0))
            XCTAssertEqual(state.currentTask?.id, "water")
        }

        do {
            let reopened = try makeDatabase(path: url.path)
            let state = try reopened.loadTodayState(now: fixedDate(dayOffset: 0))
            XCTAssertEqual(state.currentTask?.id, "water")
        }
    }

    func testDateChangeCreatesNewPlanWithoutLosingHistory() throws {
        let database = try makeDatabase()
        var state = try database.loadTodayState(now: fixedDate(dayOffset: 0))

        try database.deliverTask(in: &state, now: fixedDate(dayOffset: 0))
        try database.completeCurrentTask(in: &state, now: fixedDate(dayOffset: 0))
        XCTAssertEqual(state.totalLongevityMinutes, 2)

        let nextDayState = try database.loadTodayState(now: fixedDate(dayOffset: 1))
        XCTAssertEqual(nextDayState.totalLongevityMinutes, 0)
        XCTAssertEqual(nextDayState.completedTaskCount, 0)

        let overview = try database.loadHistoryOverview(now: fixedDate(dayOffset: 0))
        XCTAssertEqual(overview.totalLongevityMinutes, 2)
    }

    func testMonthSummariesAndClearLocalData() throws {
        let database = try makeDatabase()
        var state = try database.loadTodayState(now: fixedDate(dayOffset: 0))

        try database.deliverTask(in: &state, now: fixedDate(dayOffset: 0))
        try database.completeCurrentTask(in: &state, now: fixedDate(dayOffset: 0))

        let summaries = try database.loadMonthSummaries(containing: fixedDate(dayOffset: 0))
        XCTAssertEqual(summaries.count, 1)
        XCTAssertEqual(summaries[0].longevityMinutes, 2)
        XCTAssertEqual(summaries[0].completedTaskCount, 1)

        try database.clearAllData()

        let clearedState = try database.loadTodayState(now: fixedDate(dayOffset: 0))
        let clearedSummaries = try database.loadMonthSummaries(containing: fixedDate(dayOffset: 0))
        XCTAssertEqual(clearedState.totalLongevityMinutes, 0)
        XCTAssertTrue(clearedSummaries.isEmpty)
    }
}

private extension AppDatabaseTests {
    func makeDatabase(path: String? = nil) throws -> AppDatabase {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let taskEngine = TaskEngine(calendar: calendar, chooseCandidateIndex: { $0[0] })

        if let path {
            return try AppDatabase(path: path, calendar: calendar, taskEngine: taskEngine)
        }

        return try AppDatabase(inMemoryWith: calendar, taskEngine: taskEngine)
    }

    func fixedDate(dayOffset: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(dayOffset * 86_400))
    }

    func makeTemporaryDatabaseURL() -> (URL, () -> Void) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("HealthyVibeTests-\(UUID().uuidString)", isDirectory: true)
        let databaseURL = directory.appendingPathComponent("HealthyVibe.sqlite")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        return (
            databaseURL,
            {
                try? FileManager.default.removeItem(at: directory)
            }
        )
    }
}
