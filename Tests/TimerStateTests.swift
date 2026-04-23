import XCTest

final class TimerStateTests: XCTestCase {

    func testRemainingWhenIdleUsesDuration() {
        let state = TimerState(duration: .threeMinutes)
        XCTAssertEqual(state.remaining(at: Date()), 180, accuracy: 0.01)
    }

    func testRemainingCountsDownWhenRunning() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let state = TimerState(
            mode: .running,
            duration: .fiveMinutes,
            zeroDate: now.addingTimeInterval(120),
            updatedAt: now
        )
        XCTAssertEqual(state.remaining(at: now), 120, accuracy: 0.01)
        XCTAssertTrue(state.isCountingDown(at: now))
        XCTAssertFalse(state.isCountingUp(at: now))
    }

    func testRemainingGoesNegativeAfterZero() {
        let zero = Date(timeIntervalSince1970: 1_000_000)
        let state = TimerState(
            mode: .running,
            duration: .threeMinutes,
            zeroDate: zero,
            updatedAt: zero
        )
        let fiveAfter = zero.addingTimeInterval(5)
        XCTAssertEqual(state.remaining(at: fiveAfter), -5, accuracy: 0.01)
        XCTAssertFalse(state.isCountingDown(at: fiveAfter))
        XCTAssertTrue(state.isCountingUp(at: fiveAfter))
    }
}
