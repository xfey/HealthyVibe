import XCTest
@testable import HealthyVibeCore

final class TaskEngineTests: XCTestCase {
    func testDefaultPoolMatchesRoadmap() {
        let engine = TaskEngine()
        let state = engine.makeInitialState(for: Date(timeIntervalSince1970: 0))

        XCTAssertEqual(state.items.map(\.template.title), [
            "喝一杯水",
            "远眺 20 秒",
            "起身活动 30 秒",
            "肩颈活动 30 秒",
            "手腕活动 15 秒",
            "深呼吸 5 次"
        ])
        XCTAssertEqual(state.items.map(\.template.maxDailyCount), [8, 6, 3, 3, 3, 3])
        XCTAssertEqual(state.items.map(\.template.rewardMinutes), [2, 2, 4, 3, 2, 2])
        XCTAssertEqual(state.targetMinutes, 30)
    }

    func testCompleteCurrentTaskIncreasesProgressWithoutAutoDeliveringNextTask() {
        let engine = TaskEngine(chooseCandidateIndex: { $0[0] })
        var state = engine.makeInitialState(for: Date(timeIntervalSince1970: 0))

        let delivered = engine.deliverTask(in: &state)
        XCTAssertEqual(delivered?.id, "water")

        let completion = engine.completeCurrentTask(in: &state)
        XCTAssertEqual(completion?.rewardMinutes, 2)
        XCTAssertEqual(state.totalLongevityMinutes, 2)
        XCTAssertEqual(state.completedTaskCount, 1)
        XCTAssertNil(state.currentTask)

        if case .completed = state.cardStatus {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected completed card status after finishing one task.")
        }
    }

    func testSwitchTaskAvoidsCurrentTaskWhenAnotherCandidateExists() {
        let engine = TaskEngine(chooseCandidateIndex: { $0[0] })
        var state = engine.makeInitialState(for: Date(timeIntervalSince1970: 0))

        engine.deliverTask(in: &state)
        XCTAssertEqual(state.currentTask?.id, "water")

        engine.switchTask(in: &state)
        XCTAssertEqual(state.currentTask?.id, "look-away")
    }

    func testDepletedTaskIsNotDeliveredAgain() {
        let engine = TaskEngine(chooseCandidateIndex: { $0[0] })
        var state = engine.makeInitialState(for: Date(timeIntervalSince1970: 0))

        for _ in 0..<8 {
            engine.deliverTask(in: &state)
            XCTAssertEqual(state.currentTask?.id, "water")
            engine.completeCurrentTask(in: &state)
        }

        engine.deliverTask(in: &state)
        XCTAssertEqual(state.currentTask?.id, "look-away")
        XCTAssertTrue(state.items.first { $0.id == "water" }?.isDepleted == true)
    }

    func testDateChangeCreatesNewDailyPool() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let engine = TaskEngine(calendar: calendar, chooseCandidateIndex: { $0[0] })
        var state = engine.makeInitialState(for: Date(timeIntervalSince1970: 0))

        engine.deliverTask(in: &state, now: Date(timeIntervalSince1970: 0))
        engine.completeCurrentTask(in: &state, now: Date(timeIntervalSince1970: 0))
        XCTAssertEqual(state.totalLongevityMinutes, 2)

        engine.ensureCurrentDay(in: &state, now: Date(timeIntervalSince1970: 86_400))
        XCTAssertEqual(state.totalLongevityMinutes, 0)
        XCTAssertEqual(state.completedTaskCount, 0)
        XCTAssertNil(state.currentTask)
    }
}
