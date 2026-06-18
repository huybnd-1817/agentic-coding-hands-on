import XCTest
@testable import saa

final class AwardMapperTests: XCTestCase {

    private func makeDTO(
        thumbnail: String? = "https://example.com/x.png",
        sortOrder: Int = 3
    ) -> AwardDTO {
        AwardDTO(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            code: "top_talent",
            name_en: "Top Talent",
            name_vi: "Tài năng",
            description_en: "EN desc",
            description_vi: "VI desc",
            thumbnail_url: thumbnail,
            sort_order: sortOrder
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
}
