import XCTest
@testable import saa

// MARK: - KudosFilterTests
//
// Verifies the `isEmpty` helper used by view-layer chip rendering logic.

final class KudosFilterTests: XCTestCase {

    func testIsEmpty_bothNil_isTrue() {
        XCTAssertTrue(KudosFilter().isEmpty)
        XCTAssertTrue(KudosFilter(hashtagId: nil, departmentId: nil).isEmpty)
    }

    func testIsEmpty_hashtagSet_isFalse() {
        let filter = KudosFilter(hashtagId: UUID(), departmentId: nil)
        XCTAssertFalse(filter.isEmpty)
    }

    func testIsEmpty_departmentSet_isFalse() {
        let filter = KudosFilter(hashtagId: nil, departmentId: UUID())
        XCTAssertFalse(filter.isEmpty)
    }

    func testIsEmpty_bothSet_isFalse() {
        let filter = KudosFilter(hashtagId: UUID(), departmentId: UUID())
        XCTAssertFalse(filter.isEmpty)
    }

    func testEquatable_sameValues_areEqual() {
        let h = UUID(), d = UUID()
        XCTAssertEqual(
            KudosFilter(hashtagId: h, departmentId: d),
            KudosFilter(hashtagId: h, departmentId: d)
        )
    }

    func testEquatable_differentValues_areNotEqual() {
        XCTAssertNotEqual(
            KudosFilter(hashtagId: UUID(), departmentId: nil),
            KudosFilter(hashtagId: UUID(), departmentId: nil)
        )
    }
}
