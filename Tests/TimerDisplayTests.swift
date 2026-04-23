import XCTest
import SwiftUI

final class TimerDisplayTests: XCTestCase {

    func testFormatCountdown() {
        XCTAssertEqual(TimerDisplay.format(remaining: 180, idle: false), "3:00")
        XCTAssertEqual(TimerDisplay.format(remaining: 125, idle: false), "2:05")
        XCTAssertEqual(TimerDisplay.format(remaining: 9, idle: false), "0:09")
        XCTAssertEqual(TimerDisplay.format(remaining: 0, idle: false), "0:00")
    }

    func testFormatCountUp() {
        XCTAssertEqual(TimerDisplay.format(remaining: -1, idle: false), "+0:01")
        XCTAssertEqual(TimerDisplay.format(remaining: -83, idle: false), "+1:23")
        XCTAssertEqual(TimerDisplay.format(remaining: -600, idle: false), "+10:00")
    }
}
