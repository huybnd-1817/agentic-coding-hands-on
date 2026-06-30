import XCTest
@testable import saa

final class AwardMapperTests: XCTestCase {

    private func makeDTO(
        thumbnail: String? = "https://example.com/x.png",
        sortOrder: Int = 3,
        quantity: Int = 10,
        quantityUnit: String = "Cá nhân",
        prizeValueIndividual: String = "7.000.000 VNĐ",
        prizeValueTeam: String? = nil,
        prizeNote: String = "cho mỗi giải thưởng"
    ) -> AwardDTO {
        AwardDTO(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            code: "top_talent",
            name_en: "Top Talent",
            name_vi: "Tài năng",
            description_en: "EN desc",
            description_vi: "VI desc",
            thumbnail_url: thumbnail,
            sort_order: sortOrder,
            quantity: quantity,
            quantity_unit: quantityUnit,
            prize_value_individual: prizeValueIndividual,
            prize_value_team: prizeValueTeam,
            prize_note: prizeNote
        )
    }

    func testToDomain_mapsAllScalarFields() {
        let domain = AwardMapper.toDomain(makeDTO())

        XCTAssertEqual(domain.id, UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
        XCTAssertEqual(domain.code, "top_talent")
        XCTAssertEqual(domain.nameEN, "Top Talent")
        XCTAssertEqual(domain.nameVI, "Tài năng")
        XCTAssertEqual(domain.descriptionEN, "EN desc")
        XCTAssertEqual(domain.descriptionVI, "VI desc")
        XCTAssertEqual(domain.sortOrder, 3)
    }

    func testToDomain_parsesValidThumbnailURL() {
        let domain = AwardMapper.toDomain(makeDTO(thumbnail: "https://cdn.example.com/a.png"))
        XCTAssertEqual(domain.thumbnailURL, URL(string: "https://cdn.example.com/a.png"))
    }

    func testToDomain_nilThumbnailYieldsNilURL() {
        let domain = AwardMapper.toDomain(makeDTO(thumbnail: nil))
        XCTAssertNil(domain.thumbnailURL)
    }

    func testToDomain_preservesNegativeSortOrder() {
        let domain = AwardMapper.toDomain(makeDTO(sortOrder: -1))
        XCTAssertEqual(domain.sortOrder, -1)
    }

    // MARK: - Detail fields (Phase 08)

    func testToDomain_mapsDetailFields() {
        let domain = AwardMapper.toDomain(makeDTO(
            quantity: 10,
            quantityUnit: "Cá nhân",
            prizeValueIndividual: "7.000.000 VNĐ",
            prizeValueTeam: nil,
            prizeNote: "cho mỗi giải thưởng"
        ))

        XCTAssertEqual(domain.quantity, 10)
        XCTAssertEqual(domain.quantityUnit, "Cá nhân")
        XCTAssertEqual(domain.prizeValueIndividual, "7.000.000 VNĐ")
        XCTAssertNil(domain.prizeValueTeam)
        XCTAssertEqual(domain.prizeNote, "cho mỗi giải thưởng")
    }

    func testToDomain_mapsPrizeValueTeamWhenPresent() {
        let domain = AwardMapper.toDomain(makeDTO(
            prizeValueIndividual: "5.000.000 VNĐ",
            prizeValueTeam: "8.000.000 VNĐ",
            prizeNote: "cho giải cá nhân"
        ))

        XCTAssertEqual(domain.prizeValueIndividual, "5.000.000 VNĐ")
        XCTAssertEqual(domain.prizeValueTeam, "8.000.000 VNĐ")
        XCTAssertEqual(domain.prizeNote, "cho giải cá nhân")
    }

    // MARK: - Schema-drift regression (live DB lacking detail-screen columns)

    /// Reproduces the production keyNotFound("quantity") crash that fired
    /// when the remote DB hadn't been migrated yet. DTO now decodes missing
    /// keys to nil; mapper substitutes safe defaults so the app never crashes
    /// on schema drift.
    func testDecode_survivesMissingDetailColumns() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "code": "top_talent",
            "name_en": "Top Talent",
            "name_vi": "Tài năng",
            "description_en": "EN desc",
            "description_vi": "VI desc",
            "thumbnail_url": null,
            "sort_order": 1
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(AwardDTO.self, from: json)
        let domain = AwardMapper.toDomain(dto)

        XCTAssertEqual(domain.code, "top_talent")
        XCTAssertEqual(domain.quantity, 0)
        XCTAssertEqual(domain.quantityUnit, "")
        XCTAssertEqual(domain.prizeValueIndividual, "")
        XCTAssertNil(domain.prizeValueTeam)
        XCTAssertEqual(domain.prizeNote, "")
    }
}
