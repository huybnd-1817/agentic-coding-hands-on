import XCTest
@testable import saa

// MARK: - KudosErrorTests
//
// Verifies `messageKey` mapping and Equatable behaviour:
//   - .unknown wrappers are equal even when underlying differs (documented in the type).
//   - Different concrete cases are never equal.
//   - Every case exposes a non-empty messageKey so the UI never renders ""

final class KudosErrorTests: XCTestCase {

    func testMessageKey_everyCaseReturnsNonEmptyKey() {
        let cases: [KudosError] = [
            .network,
            .notAuthenticated,
            .cannotLikeOwnKudos,
            .alreadyLiked,
            .unknown(underlying: "x")
        ]
        for error in cases {
            let key = error.messageKey ?? ""
            XCTAssertFalse(key.isEmpty, "messageKey for \(error) should not be empty")
            XCTAssertTrue(key.hasPrefix("kudos.error."), "messageKey for \(error) must live under kudos.error.*")
        }
    }

    func testEquatable_sameCase_isEqual() {
        XCTAssertEqual(KudosError.network,           KudosError.network)
        XCTAssertEqual(KudosError.notAuthenticated,  KudosError.notAuthenticated)
        XCTAssertEqual(KudosError.alreadyLiked,      KudosError.alreadyLiked)
        XCTAssertEqual(KudosError.cannotLikeOwnKudos, KudosError.cannotLikeOwnKudos)
    }

    func testEquatable_unknownIgnoresUnderlying() {
        XCTAssertEqual(
            KudosError.unknown(underlying: "foo"),
            KudosError.unknown(underlying: "bar"),
            "Equality for .unknown ignores the wrapped underlying string by design"
        )
    }

    func testEquatable_distinctCases_areNotEqual() {
        XCTAssertNotEqual(KudosError.network,       KudosError.notAuthenticated)
        XCTAssertNotEqual(KudosError.alreadyLiked,  KudosError.cannotLikeOwnKudos)
        XCTAssertNotEqual(KudosError.network,       KudosError.unknown(underlying: ""))
    }

    func testErrorDescription_resolvesToLocalizedString() {
        // We don't assert the translated copy (avoid coupling to xcstrings),
        // but `errorDescription` must produce a non-nil value because every
        // case has a messageKey and Localizable.xcstrings carries that key
        // (verified separately by KudosLocalizationKeysExistTests).
        XCTAssertNotNil(KudosError.network.errorDescription)
        XCTAssertNotNil(KudosError.unknown(underlying: "x").errorDescription)
    }
}
