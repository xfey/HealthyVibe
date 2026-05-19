import XCTest
@testable import HealthyVibeCore

final class ActiveTimeAccumulatorTests: XCTestCase {
    func testActiveTimeTriggersFallbackAfterInterval() {
        var accumulator = ActiveTimeAccumulator(fallbackInterval: 60)

        XCTAssertFalse(accumulator.advance(by: 30))
        XCTAssertEqual(accumulator.activeSecondsSinceHook, 30)
        XCTAssertTrue(accumulator.advance(by: 30))
        XCTAssertEqual(accumulator.activeSecondsSinceHook, 0)
    }

    func testInactiveTimeDoesNotAccumulate() {
        var accumulator = ActiveTimeAccumulator(fallbackInterval: 60)

        accumulator.setActive(false)
        XCTAssertFalse(accumulator.advance(by: 120))
        XCTAssertEqual(accumulator.activeSecondsSinceHook, 0)

        accumulator.setActive(true)
        XCTAssertFalse(accumulator.advance(by: 30))
        XCTAssertEqual(accumulator.activeSecondsSinceHook, 30)
    }

    func testHookEventResetsFallbackClock() {
        var accumulator = ActiveTimeAccumulator(fallbackInterval: 60)

        accumulator.advance(by: 50)
        accumulator.recordHookEvent()
        XCTAssertEqual(accumulator.activeSecondsSinceHook, 0)
        XCTAssertFalse(accumulator.advance(by: 50))
    }
}
