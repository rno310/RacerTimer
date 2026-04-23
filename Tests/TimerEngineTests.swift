import XCTest

@MainActor
final class TimerEngineTests: XCTestCase {

    private var fixedNow: Date!
    private var clock: (() -> Date)!
    private var signaler: RecordingSignaler!

    override func setUp() async throws {
        fixedNow = Date(timeIntervalSince1970: 1_000_000)
        clock = { [weak self] in self?.fixedNow ?? Date() }
        signaler = RecordingSignaler()
    }

    private func makeEngine(duration: StartDuration = .threeMinutes) -> TimerEngine {
        TimerEngine(
            state: TimerState(duration: duration),
            signaler: signaler,
            clock: clock
        )
    }

    // MARK: - State transitions

    func testInitialStateIsIdle() {
        let engine = makeEngine()
        XCTAssertEqual(engine.state.mode, .idle)
        XCTAssertNil(engine.state.zeroDate)
        XCTAssertTrue(engine.isIdle)
    }

    func testStartSetsZeroDateAtDurationAhead() {
        let engine = makeEngine(duration: .threeMinutes)
        engine.start()
        XCTAssertEqual(engine.state.mode, .running)
        let zero = try! XCTUnwrap(engine.state.zeroDate)
        XCTAssertEqual(zero.timeIntervalSince(fixedNow), 180, accuracy: 0.01)
    }

    func testSetDurationNoOpWhileRunning() {
        let engine = makeEngine(duration: .threeMinutes)
        engine.start()
        engine.setDuration(.fiveMinutes)
        XCTAssertEqual(engine.state.duration, .threeMinutes)
    }

    func testSetDurationWorksWhileIdle() {
        let engine = makeEngine(duration: .threeMinutes)
        engine.setDuration(.fiveMinutes)
        XCTAssertEqual(engine.state.duration, .fiveMinutes)
    }

    // MARK: - Plus / minus

    func testPlusOneAddsSixtySeconds() {
        let engine = makeEngine()
        engine.start()
        let before = engine.state.zeroDate!
        engine.plusOne()
        XCTAssertEqual(engine.state.zeroDate!.timeIntervalSince(before), 60, accuracy: 0.01)
    }

    func testMinusOneSubtractsSixtySeconds() {
        let engine = makeEngine(duration: .fiveMinutes)
        engine.start()
        let before = engine.state.zeroDate!
        engine.minusOne()
        XCTAssertEqual(engine.state.zeroDate!.timeIntervalSince(before), -60, accuracy: 0.01)
    }

    func testMinusOneIgnoredWhenRemainingBelowOneMinute() {
        let engine = makeEngine()
        engine.start()
        // Advance clock to 40s remaining
        fixedNow = engine.state.zeroDate!.addingTimeInterval(-40)
        engine.advance(to: fixedNow)
        let before = engine.state.zeroDate!
        engine.minusOne()
        XCTAssertEqual(engine.state.zeroDate!, before, "minusOne must not change state with < 60s remaining")
    }

    func testPlusOneIgnoredInCountUp() {
        let engine = makeEngine()
        engine.start()
        fixedNow = engine.state.zeroDate!.addingTimeInterval(5) // past zero
        engine.advance(to: fixedNow)
        let before = engine.state.zeroDate!
        engine.plusOne()
        XCTAssertEqual(engine.state.zeroDate!, before)
    }

    // MARK: - Sync

    func testSyncFloorsToCurrentMinute() {
        let engine = makeEngine(duration: .fiveMinutes)
        engine.start()
        // Move 13 seconds in: remaining = 287s = 4:47
        fixedNow = fixedNow.addingTimeInterval(13)
        engine.advance(to: fixedNow)
        engine.sync()
        // 4:47 floors to 4:00 → remaining = 240
        let remaining = engine.state.zeroDate!.timeIntervalSince(fixedNow)
        XCTAssertEqual(remaining, 240, accuracy: 0.01)
    }

    func testSyncIgnoredWhenRemainingBelowOneMinute() {
        let engine = makeEngine()
        engine.start()
        fixedNow = engine.state.zeroDate!.addingTimeInterval(-40) // 0:40 remaining
        engine.advance(to: fixedNow)
        let before = engine.state.zeroDate!
        engine.sync()
        XCTAssertEqual(engine.state.zeroDate!, before)
    }

    func testSyncAtExactMinuteIsStable() {
        let engine = makeEngine(duration: .fiveMinutes)
        engine.start()
        // Move exactly 60 s → remaining 240 (4:00 sharp)
        fixedNow = fixedNow.addingTimeInterval(60)
        engine.advance(to: fixedNow)
        engine.sync()
        let remaining = engine.state.zeroDate!.timeIntervalSince(fixedNow)
        XCTAssertEqual(remaining, 240, accuracy: 0.01)
    }

    // MARK: - Reset

    func testResetReturnsToIdle() {
        let engine = makeEngine()
        engine.start()
        engine.reset()
        XCTAssertEqual(engine.state.mode, .idle)
        XCTAssertNil(engine.state.zeroDate)
        XCTAssertEqual(engine.pendingEventCount, 0)
    }

    // MARK: - Signal firing

    func testCountdownFiresExpectedSignalsInOrder() {
        let engine = makeEngine(duration: .threeMinutes)
        engine.start()
        let zero = try! XCTUnwrap(engine.state.zeroDate)

        // Walk forward in ascending fire-date order (events are sorted descending by secondsBeforeZero).
        let expected = SignalSchedule.events(for: .threeMinutes)
        for ev in expected.reversed() {
            fixedNow = zero.addingTimeInterval(-TimeInterval(ev.secondsBeforeZero) + 0.05)
            engine.advance(to: fixedNow)
        }

        // Fire order = ascending fireDate = descending secondsBeforeZero = events in declared order.
        XCTAssertEqual(signaler.played.count, expected.count)
        XCTAssertEqual(signaler.played, expected.map { $0.kind })
    }

    func testPlusOneDuringCountdownAddsNewMinuteEvent() {
        let engine = makeEngine(duration: .threeMinutes)
        engine.start()

        // Fast-forward to 0:45 remaining
        fixedNow = engine.state.zeroDate!.addingTimeInterval(-45)
        engine.advance(to: fixedNow)
        signaler.reset()

        // Now plusOne → remaining becomes 1:45 and zeroDate moves 60s later
        engine.plusOne()

        // Advance to new zero — we should now hear 1:00 (long), 0:30, 0:20, 0:10, 5 shorts, start
        let newZero = engine.state.zeroDate!
        fixedNow = newZero.addingTimeInterval(1)
        engine.advance(to: fixedNow)

        // Should include 1:00 long, 0:30 3short, 0:20 2short, 0:10 1short, 5 shorts at last 5, start
        XCTAssertTrue(signaler.played.contains(.long))
        XCTAssertTrue(signaler.played.contains(.shortBurst(count: 3)))
        XCTAssertTrue(signaler.played.contains(.startSignal))
    }

    // MARK: - Remote state apply

    func testApplyNewerRemoteStateOverrides() {
        let engine = makeEngine()
        engine.start()
        let newer = TimerState(
            mode: .running,
            duration: .fiveMinutes,
            zeroDate: fixedNow.addingTimeInterval(300),
            updatedAt: fixedNow.addingTimeInterval(10)
        )
        engine.apply(remoteState: newer)
        XCTAssertEqual(engine.state.duration, .fiveMinutes)
        XCTAssertEqual(engine.state.zeroDate, newer.zeroDate)
    }

    func testApplyOlderRemoteStateIgnored() {
        let engine = makeEngine()
        fixedNow = fixedNow.addingTimeInterval(10)
        engine.start() // state.updatedAt is now
        let older = TimerState(
            mode: .running,
            duration: .fiveMinutes,
            zeroDate: fixedNow.addingTimeInterval(300),
            updatedAt: fixedNow.addingTimeInterval(-5)
        )
        let before = engine.state
        engine.apply(remoteState: older)
        XCTAssertEqual(engine.state, before)
    }
}
