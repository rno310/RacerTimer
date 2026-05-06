import XCTest

final class SignalScheduleTests: XCTestCase {

    func testThreeMinuteScheduleContent() {
        let events = SignalSchedule.events(for: .threeMinutes)
        let map = Dictionary(uniqueKeysWithValues: events.map { ($0.secondsBeforeZero, $0.kind) })

        XCTAssertEqual(map[180], .longsPlusShorts(longs: 3, shorts: 0))
        XCTAssertEqual(map[120], .longsPlusShorts(longs: 2, shorts: 0))
        XCTAssertNil(map[240], "no 4-minute mark in 3-min mode")
        XCTAssertNil(map[300], "no 5-minute mark in 3-min mode")

        XCTAssertEqual(map[150], .longsPlusShorts(longs: 2, shorts: 3))
        XCTAssertEqual(map[90], .longsPlusShorts(longs: 1, shorts: 3))
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

        XCTAssertEqual(map[300], .longsPlusShorts(longs: 5, shorts: 0))
        XCTAssertEqual(map[240], .longsPlusShorts(longs: 4, shorts: 0))
        XCTAssertEqual(map[180], .longsPlusShorts(longs: 3, shorts: 0))
        XCTAssertEqual(map[150], .longsPlusShorts(longs: 2, shorts: 3))
        XCTAssertEqual(map[120], .longsPlusShorts(longs: 2, shorts: 0))

        XCTAssertEqual(map[90], .longsPlusShorts(longs: 1, shorts: 3))
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
        XCTAssertEqual(SignalSchedule.events(for: .threeMinutes).count, 20)
        XCTAssertEqual(SignalSchedule.events(for: .fiveMinutes).count, 28)
    }

    func testFifteenSecondTicksThreeMinute() {
        let events = SignalSchedule.events(for: .threeMinutes)
        let map = Dictionary(uniqueKeysWithValues: events.map { ($0.secondsBeforeZero, $0.kind) })
        for t in [165, 135, 105, 75, 45, 15] {
            XCTAssertEqual(map[t], .short, "expected .short at \(t)s")
        }
    }

    func testFifteenSecondTicksFiveMinute() {
        let events = SignalSchedule.events(for: .fiveMinutes)
        let map = Dictionary(uniqueKeysWithValues: events.map { ($0.secondsBeforeZero, $0.kind) })
        for t in [285, 270, 255, 225, 210, 195, 165, 135, 105, 75, 45, 15] {
            XCTAssertEqual(map[t], .short, "expected .short at \(t)s")
        }
    }

    func testOneMinuteMarkIsSingleLong() {
        let events = SignalSchedule.events(for: .threeMinutes)
        let minuteBand = events.filter { (60...61).contains($0.secondsBeforeZero) }
        XCTAssertEqual(minuteBand.count, 1)
        XCTAssertEqual(minuteBand.first?.kind, .long)
    }
}
