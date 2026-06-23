import XCTest
@testable import saa

// MARK: - LightweightMappersTests
//
// Covers the four trivial DTO → Domain mappers that have no other test file:
//   - HashtagMapper / DepartmentMapper / UserStatsMapper — straight field copy.
//   - EventBonusMapper — copy plus the `label ?? ""` fallback.
//
// These are cheap to verify and protect against silent rename / column-swap
// regressions in the wire format.

final class LightweightMappersTests: XCTestCase {

    // MARK: - HashtagMapper

    func testHashtagMapper_copiesIdAndTagVerbatim() {
        let id = UUID()
        let result = HashtagMapper.from(HashtagDTO(id: id, tag: "#Teamwork"))
        XCTAssertEqual(result.id, id)
        XCTAssertEqual(result.tag, "#Teamwork")
    }

    // MARK: - DepartmentMapper

    func testDepartmentMapper_copiesAllFields() {
        let id = UUID()
        let dto = DepartmentDTO(id: id, code: "CEV1", name: "CEV1 - Customer Experience Vietnam 1")
        let result = DepartmentMapper.from(dto)

        XCTAssertEqual(result.id,   id)
        XCTAssertEqual(result.code, "CEV1")
        XCTAssertEqual(result.name, "CEV1 - Customer Experience Vietnam 1")
    }

    // MARK: - UserStatsMapper

    func testUserStatsMapper_copiesAllSnakeCaseFields() {
        let userId = UUID()
        let updated = Date(timeIntervalSince1970: 1_700_000_000)
        let dto = UserStatsDTO(
            user_id: userId,
            kudos_received_count: 11,
            kudos_sent_count: 7,
            kudos_hearts_received: 33,
            secret_boxes_opened: 2,
            secret_boxes_unopened: 4,
            updated_at: updated
        )
        let result = UserStatsMapper.from(dto)

        XCTAssertEqual(result.userId,              userId)
        XCTAssertEqual(result.kudosReceivedCount,  11)
        XCTAssertEqual(result.kudosSentCount,      7)
        XCTAssertEqual(result.kudosHeartsReceived, 33)
        XCTAssertEqual(result.secretBoxesOpened,   2)
        XCTAssertEqual(result.secretBoxesUnopened, 4)
        XCTAssertEqual(result.updatedAt,           updated)
    }

    // MARK: - EventBonusMapper

    func testEventBonusMapper_withLabel_copiesLabel() {
        let id = UUID()
        let starts = Date(timeIntervalSince1970: 100)
        let ends   = Date(timeIntervalSince1970: 200)
        let dto = EventBonusDTO(id: id, starts_at: starts, ends_at: ends, multiplier: 2, label: "Double Heart Day")

        let result = EventBonusMapper.from(dto)

        XCTAssertEqual(result.id,         id)
        XCTAssertEqual(result.startsAt,   starts)
        XCTAssertEqual(result.endsAt,     ends)
        XCTAssertEqual(result.multiplier, 2)
        XCTAssertEqual(result.label,      "Double Heart Day")
    }

    func testEventBonusMapper_nilLabel_fallsBackToEmptyString() {
        let dto = EventBonusDTO(
            id: UUID(),
            starts_at: Date(timeIntervalSince1970: 0),
            ends_at:   Date(timeIntervalSince1970: 1),
            multiplier: 1,
            label: nil
        )
        let result = EventBonusMapper.from(dto)
        XCTAssertEqual(result.label, "", "nil label MUST collapse to empty string so Domain never carries nil")
    }
}
