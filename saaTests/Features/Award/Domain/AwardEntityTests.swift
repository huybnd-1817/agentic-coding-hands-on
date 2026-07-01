import XCTest
@testable import saa

// MARK: - AwardEntityTests
//
// Pure-domain tests on the `Award` entity:
//   - Equatable semantics: Swift synthesized full-structural equality (all fields compared)
//   - Dual-prize branching: Signature variant has non-nil `prizeValueTeam`; others nil
//   - Localization: title/subtitle resolution by locale language code

final class AwardEntityTests: XCTestCase {

    // MARK: - Equatable
    //
    // `Award` uses Swift's synthesized `Equatable`, which compares ALL stored
    // properties. Two awards with the same id but different content are NOT equal —
    // this is intentional: `AwardDetailViewModel.select()` compares by `.id`
    // directly, so `==` is reserved for full structural equality.

    /// Two Award values with identical fields in every property are equal.
    func testEquatable_sameFields_areEqual() {
        let id = UUID()
        let award1 = Award(
            id: id,
            code: "top_talent",
            nameEN: "Top Talent",
            nameVI: "Tài năng",
            descriptionEN: "EN",
            descriptionVI: "VI",
            thumbnailURL: nil,
            sortOrder: 1,
            quantity: 10,
            quantityUnit: "Cá nhân",
            prizeValueIndividual: "7.000.000 VNĐ",
            prizeValueTeam: nil,
            prizeNote: "cho mỗi giải thưởng"
        )
        let award2 = Award(
            id: id,
            code: "top_talent",
            nameEN: "Top Talent",
            nameVI: "Tài năng",
            descriptionEN: "EN",
            descriptionVI: "VI",
            thumbnailURL: nil,
            sortOrder: 1,
            quantity: 10,
            quantityUnit: "Cá nhân",
            prizeValueIndividual: "7.000.000 VNĐ",
            prizeValueTeam: nil,
            prizeNote: "cho mỗi giải thưởng"
        )

        XCTAssertEqual(award1, award2, "Awards with identical fields must be equal")
    }

    /// Two Award values that differ only in `id` are not equal (full structural equality).
    func testEquatable_differentId_areNotEqual() {
        let id1 = UUID()
        let id2 = UUID()
        let award1 = Award(
            id: id1,
            code: "top_talent",
            nameEN: "Top Talent",
            nameVI: "Tài năng",
            descriptionEN: "EN",
            descriptionVI: "VI",
            thumbnailURL: nil,
            sortOrder: 1,
            quantity: 10,
            quantityUnit: "Cá nhân",
            prizeValueIndividual: "7.000.000 VNĐ",
            prizeValueTeam: nil,
            prizeNote: "cho mỗi giải thưởng"
        )
        let award2 = Award(
            id: id2,
            code: "top_talent",
            nameEN: "Top Talent",
            nameVI: "Tài năng",
            descriptionEN: "EN",
            descriptionVI: "VI",
            thumbnailURL: nil,
            sortOrder: 1,
            quantity: 10,
            quantityUnit: "Cá nhân",
            prizeValueIndividual: "7.000.000 VNĐ",
            prizeValueTeam: nil,
            prizeNote: "cho mỗi giải thưởng"
        )

        XCTAssertNotEqual(award1, award2, "Awards with different id must not be equal")
    }

    /// Two Award values with the same id but different content are not equal.
    /// Documents the deliberate full-structural semantic: `==` is not an id-only check.
    func testEquatable_differentCode_areNotEqual() {
        let id = UUID()
        let award1 = Award(
            id: id,
            code: "top_talent",
            nameEN: "Top Talent",
            nameVI: "Tài năng",
            descriptionEN: "EN",
            descriptionVI: "VI",
            thumbnailURL: nil,
            sortOrder: 1,
            quantity: 10,
            quantityUnit: "Cá nhân",
            prizeValueIndividual: "7.000.000 VNĐ",
            prizeValueTeam: nil,
            prizeNote: "cho mỗi giải thưởng"
        )
        let award2 = Award(
            id: id,
            code: "top_project",  // same id, different content
            nameEN: "Top Project",
            nameVI: "Dự án",
            descriptionEN: "Different EN",
            descriptionVI: "Khác VI",
            thumbnailURL: nil,
            sortOrder: 2,
            quantity: 2,
            quantityUnit: "Tập thể",
            prizeValueIndividual: "15.000.000 VNĐ",
            prizeValueTeam: nil,
            prizeNote: "cho mỗi giải thưởng"
        )

        XCTAssertNotEqual(award1, award2, "Awards with same id but different fields must not be equal")
    }

    // MARK: - Dual-prize branching

    func testSignatureVariant_hasPrizeValueTeam() {
        let signature = Award(
            id: UUID(),
            code: "signature_2026_creator",
            nameEN: "Signature Creator",
            nameVI: "Signature Creator",
            descriptionEN: "EN",
            descriptionVI: "VI",
            thumbnailURL: nil,
            sortOrder: 5,
            quantity: 1,
            quantityUnit: "Cá nhân hoặc tập thể",
            prizeValueIndividual: "5.000.000 VNĐ",
            prizeValueTeam: "8.000.000 VNĐ",
            prizeNote: "cho giải cá nhân"
        )

        XCTAssertNotNil(
            signature.prizeValueTeam,
            "Signature variant must have non-nil prizeValueTeam"
        )
        XCTAssertEqual(
            signature.prizeValueTeam,
            "8.000.000 VNĐ"
        )
    }

    func testNonSignatureVariants_prizeValueTeamIsNil() {
        let codes = ["top_talent", "top_project", "top_project_leader", "best_manager", "mvp"]
        for code in codes {
            let award = Award(
                id: UUID(),
                code: code,
                nameEN: code,
                nameVI: code,
                descriptionEN: "EN",
                descriptionVI: "VI",
                thumbnailURL: nil,
                sortOrder: 1,
                quantity: 1,
                quantityUnit: "Cá nhân",
                prizeValueIndividual: "7.000.000 VNĐ",
                prizeValueTeam: nil,
                prizeNote: "cho mỗi giải thưởng"
            )

            XCTAssertNil(
                award.prizeValueTeam,
                "Code '\(code)' must have nil prizeValueTeam"
            )
        }
    }

    // MARK: - Localization

    func testTitle_viLocaleReturnsNameVI() {
        let award = Award(
            id: UUID(),
            code: "top_talent",
            nameEN: "Top Talent",
            nameVI: "Tài năng",
            descriptionEN: "EN",
            descriptionVI: "VI",
            thumbnailURL: nil,
            sortOrder: 1,
            quantity: 10,
            quantityUnit: "Cá nhân",
            prizeValueIndividual: "7.000.000 VNĐ",
            prizeValueTeam: nil,
            prizeNote: "cho mỗi giải thưởng"
        )

        var viLocale = Locale(identifier: "vi_VN")
        let title = award.title(for: viLocale)

        XCTAssertEqual(title, "Tài năng", "vi locale must return nameVI")
    }

    func testTitle_enLocaleReturnsNameEN() {
        let award = Award(
            id: UUID(),
            code: "top_talent",
            nameEN: "Top Talent",
            nameVI: "Tài năng",
            descriptionEN: "EN",
            descriptionVI: "VI",
            thumbnailURL: nil,
            sortOrder: 1,
            quantity: 10,
            quantityUnit: "Cá nhân",
            prizeValueIndividual: "7.000.000 VNĐ",
            prizeValueTeam: nil,
            prizeNote: "cho mỗi giải thưởng"
        )

        let enLocale = Locale(identifier: "en_US")
        let title = award.title(for: enLocale)

        XCTAssertEqual(title, "Top Talent", "en locale must return nameEN")
    }

    func testSubtitle_viLocaleReturnsDescriptionVI() {
        let award = Award(
            id: UUID(),
            code: "top_talent",
            nameEN: "Top Talent",
            nameVI: "Tài năng",
            descriptionEN: "Excellent individual",
            descriptionVI: "Cá nhân xuất sắc",
            thumbnailURL: nil,
            sortOrder: 1,
            quantity: 10,
            quantityUnit: "Cá nhân",
            prizeValueIndividual: "7.000.000 VNĐ",
            prizeValueTeam: nil,
            prizeNote: "cho mỗi giải thưởng"
        )

        let viLocale = Locale(identifier: "vi_VN")
        let subtitle = award.subtitle(for: viLocale)

        XCTAssertEqual(subtitle, "Cá nhân xuất sắc", "vi locale must return descriptionVI")
    }

    func testSubtitle_enLocaleReturnsDescriptionEN() {
        let award = Award(
            id: UUID(),
            code: "top_talent",
            nameEN: "Top Talent",
            nameVI: "Tài năng",
            descriptionEN: "Excellent individual",
            descriptionVI: "Cá nhân xuất sắc",
            thumbnailURL: nil,
            sortOrder: 1,
            quantity: 10,
            quantityUnit: "Cá nhân",
            prizeValueIndividual: "7.000.000 VNĐ",
            prizeValueTeam: nil,
            prizeNote: "cho mỗi giải thưởng"
        )

        let enLocale = Locale(identifier: "en_US")
        let subtitle = award.subtitle(for: enLocale)

        XCTAssertEqual(subtitle, "Excellent individual", "en locale must return descriptionEN")
    }
}
