import XCTest

final class SignalScheduleTests: XCTestCase {

    func testThreeMinuteScheduleContent() {
        let events = SignalSchedule.events(for: .threeMinutes)
        let map = Dictionary(uniqueKeysWithValues: events.map { ($0.secondsBeforeZero, $0.kind) })

        XCTAssertEqual(map[180], .long)
        XCTAssertEqual(map[120], .long)
        XCTAssertNil(map[240], "no 4-minute mark in 3-min mode")
        XCTAssertNil(map[300], "no 5-minute mark in 3-min mode")

        XCTAssertEqual(map[90], .longPlusShorts(count: 3))
        XCTAssertEqual(map[60], .long)
        XCTAssertEqual(map[30], .shortBurst(count: 3))
        XCTAssertEqual(map[20], .shortBurst(count: 2))
        XCTAssertEqual(map[10], .shortBurst(count: 1))

        for s in 1...5 {
            XCTAssertEqual(map[s], .short, "expected .short at \(s)s")
        }
        XCTAssertEqual(map[0], .startSignal)
    }

    func testFiveMinuteScheduleContent() {
        let events = SignalSchedule.events(for: .fiveMinutes)
        let map = Dictionary(uniqueKeysWithValues: events.map { ($0.secondsBeforeZero, $0.kind) })

        XCTAssertEqual(map[300], .long)
        XCTAssertEqual(map[240], .long)
        XCTAssertEqual(map[180], .long)
        XCTAssertEqual(map[120], .long)

        XCTAssertEqual(map[90], .longPlusShorts(count: 3))
        XCTAssertEqual(map[60], .long)
        XCTAssertEqual(map[30], .shortBurst(count: 3))
        XCTAssertEqual(map[20], .shortBurst(count: 2))
        XCTAssertEqual(map[10], .shortBurst(count: 1))
        XCTAssertEqual(map[0], .startSignal)
    }

    func testScheduleOrderedDescending() {
        let events = SignalSchedule.events(for: .fiveMinutes)
        let keys = events.map { $0.secondsBeforeZero }
        XCTAssertEqual(keys, keys.sorted(by: >))
    }

    func testScheduleCountsAreExact() {
        XCTAssertEqual(SignalSchedule.events(for: .threeMinutes).count, 13)
        XCTAssertEqual(SignalSchedule.events(for: .fiveMinutes).count, 15)
    }

    func testNoMinuteMarkAtOrBelowOneMinute() {
        let events = SignalSchedule.events(for: .threeMinutes)
        let minuteBand = events.filter { (60...61).contains($0.secondsBeforeZero) }
        XCTAssertEqual(minuteBand.count, 1)
        XCTAssertEqual(minuteBand.first?.kind, .long)
    }
}
