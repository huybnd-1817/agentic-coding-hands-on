import XCTest
@testable import saa

// MARK: - EventBonusActiveTests
//
// Verifies `EventBonus.isActive(now:)` correctly evaluates the time window.
// Bounds are INCLUSIVE on both ends per spec (startsAt and endsAt are inclusive).

final class EventBonusActiveTests: XCTestCase {

    // MARK: - Helpers

    private let testUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let baseDate = Date(timeIntervalSince1970: 0)

    private func makeBonus(startsAt: Date, endsAt: Date) -> EventBonus {
        EventBonus(
            id: testUUID,
            startsAt: startsAt,
            endsAt: endsAt,
            multiplier: 2,
            label: "Double Heart Day"
        )
    }

    // MARK: - Tests

    func testNowBeforeWindow_isFalse() {
        let bonus = makeBonus(
            startsAt: baseDate.addingTimeInterval(1000),
            endsAt: baseDate.addingTimeInterval(2000)
        )
        let now = baseDate  // before startsAt
        XCTAssertFalse(bonus.isActive(now: now))
    }

    func testNowEqualsStartsAt_isTrue() {
        let startsAt = baseDate.addingTimeInterval(1000)
        let bonus = makeBonus(
            startsAt: startsAt,
            endsAt: baseDate.addingTimeInterval(2000)
        )
        let now = startsAt  // inclusive
        XCTAssertTrue(bonus.isActive(now: now))
    }

    func testNowBetweenWindow_isTrue() {
        let bonus = makeBonus(
            startsAt: baseDate.addingTimeInterval(1000),
            endsAt: baseDate.addingTimeInterval(2000)
        )
        let now = baseDate.addingTimeInterval(1500)  // between
        XCTAssertTrue(bonus.isActive(now: now))
    }

    func testNowEqualsEndsAt_isTrue() {
        let endsAt = baseDate.addingTimeInterval(2000)
        let bonus = makeBonus(
            startsAt: baseDate.addingTimeInterval(1000),
            endsAt: endsAt
        )
        let now = endsAt  // inclusive
        XCTAssertTrue(bonus.isActive(now: now))
    }

    func testNowAfterWindow_isFalse() {
        let bonus = makeBonus(
            startsAt: baseDate.addingTimeInterval(1000),
            endsAt: baseDate.addingTimeInterval(2000)
        )
        let now = baseDate.addingTimeInterval(3000)  // after endsAt
        XCTAssertFalse(bonus.isActive(now: now))
    }
}
