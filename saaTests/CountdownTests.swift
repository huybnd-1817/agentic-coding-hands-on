import XCTest
@testable import saa

// MARK: - CountdownTests
//
// Verifies the pure value-type math in `Countdown.until(_:from:)`:
//   - Clamps to zero when target is in the past.
//   - Computes days/hours/minutes correctly for a future target.
// Closes TC_FUN_001 (countdown updates toward 26/12/2025) and TC_FUN_002
// (post-event behavior) at the unit level.

final class CountdownTests: XCTestCase {

    // MARK: - Clamping

    func testClampsToZeroWhenTargetIsInThePast() {
        let now    = Date(timeIntervalSince1970: 1_750_000_000) // arbitrary future date
        let target = now.addingTimeInterval(-86_400)            // 1 day before now
        XCTAssertEqual(Countdown.until(target, from: now), .zero)
    }

    func testClampsToZeroWhenTargetEqualsNow() {
        let now = Date(timeIntervalSince1970: 1_750_000_000)
        XCTAssertEqual(Countdown.until(now, from: now), .zero)
    }

    // MARK: - Happy path

    func testComputesDaysHoursMinutesForFutureTarget() {
        let now = Date(timeIntervalSince1970: 0)
        // 2 days, 3 hours, 4 minutes, 5 seconds ahead — seconds truncated.
        let twoDays: TimeInterval     = 2 * 86_400
        let threeHours: TimeInterval  = 3 * 3_600
        let fourMinutes: TimeInterval = 4 * 60
        let interval                  = twoDays + threeHours + fourMinutes + 5
        let target                    = now.addingTimeInterval(interval)
        XCTAssertEqual(
            Countdown.until(target, from: now),
            Countdown(days: 2, hours: 3, minutes: 4)
        )
    }

    func testComputesZeroDaysForSubDayInterval() {
        let now             = Date(timeIntervalSince1970: 0)
        let fiveHours: TimeInterval     = 5 * 3_600
        let thirtyMinutes: TimeInterval = 30 * 60
        let target          = now.addingTimeInterval(fiveHours + thirtyMinutes)
        XCTAssertEqual(
            Countdown.until(target, from: now),
            Countdown(days: 0, hours: 5, minutes: 30)
        )
    }
}
