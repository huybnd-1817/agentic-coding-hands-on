import XCTest
@testable import saa

// MARK: - StarTierTests
//
// Verifies `StarTier.from(received:)` derives tiers correctly using floor thresholds.
// Thresholds (per clarifications.md):
//   - 0 – 9   → `.zero`
//   - 10 – 19 → `.one`
//   - 20 – 49 → `.two`
//   - ≥ 50    → `.three`

final class StarTierTests: XCTestCase {

    // MARK: - Tier `.zero` (0–9)

    func testFromZeroToNine_returnsZero() {
        XCTAssertEqual(StarTier.from(received: 0), .zero)
        XCTAssertEqual(StarTier.from(received: 5), .zero)
        XCTAssertEqual(StarTier.from(received: 9), .zero)
    }

    // MARK: - Tier `.one` (10–19)

    func testFromTenToNineteen_returnsOne() {
        XCTAssertEqual(StarTier.from(received: 10), .one)
        XCTAssertEqual(StarTier.from(received: 15), .one)
        XCTAssertEqual(StarTier.from(received: 19), .one)
    }

    // MARK: - Tier `.two` (20–49)

    func testFromTwentyToFortynine_returnsTwo() {
        XCTAssertEqual(StarTier.from(received: 20), .two)
        XCTAssertEqual(StarTier.from(received: 35), .two)
        XCTAssertEqual(StarTier.from(received: 49), .two)
    }

    // MARK: - Tier `.three` (≥50)

    func testFromFiftyAndAbove_returnsThree() {
        XCTAssertEqual(StarTier.from(received: 50), .three)
        XCTAssertEqual(StarTier.from(received: 100), .three)
        XCTAssertEqual(StarTier.from(received: 1000), .three)
    }

    // MARK: - Defensive: negative input (floor-based, ≥0 per clarifications)

    func testFromNegative_treatsAsZero() {
        XCTAssertEqual(StarTier.from(received: -1), .zero)
        XCTAssertEqual(StarTier.from(received: -100), .zero)
    }
}
