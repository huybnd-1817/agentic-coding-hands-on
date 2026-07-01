import XCTest
@testable import saa

// MARK: - AwardLocalizationKeysExistTests
//
// Asserts every award.detail.* key added in Phase 11 is present in
// Localizable.xcstrings and resolves to a non-key value in both vi and en.
//
// Strategy: load each lproj bundle explicitly so locale detection does not
// interfere. `localizedString(forKey:value:table:)` returns the key itself
// when no translation is found — asserting `resolved != key` catches both
// missing keys and identity translations.

final class AwardLocalizationKeysExistTests: XCTestCase {

    // MARK: - Properties

    private var viBundle: Bundle!
    private var enBundle: Bundle!

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        let appBundle = Bundle(for: type(of: self)).principal ?? Bundle.main
        guard let viPath = appBundle.path(forResource: "vi", ofType: "lproj"),
              let enPath = appBundle.path(forResource: "en", ofType: "lproj"),
              let viB = Bundle(path: viPath),
              let enB = Bundle(path: enPath) else {
            viBundle = appBundle
            enBundle = appBundle
            return
        }
        viBundle = viB
        enBundle = enB
    }

    // MARK: - Helpers

    private func resolved(_ key: String, in bundle: Bundle) -> String {
        bundle.localizedString(forKey: key, value: nil, table: "Localizable")
    }

    private func assertKeyExists(_ key: String, file: StaticString = #file, line: UInt = #line) {
        let viValue = resolved(key, in: viBundle)
        XCTAssertNotEqual(
            viValue, key,
            "Missing vi translation for '\(key)'",
            file: file, line: line
        )
        let enValue = resolved(key, in: enBundle)
        XCTAssertNotEqual(
            enValue, key,
            "Missing en translation for '\(key)'",
            file: file, line: line
        )
    }

    // MARK: - award.detail.*

    func testEyebrow()                  { assertKeyExists("award.detail.eyebrow") }
    func testTitle()                    { assertKeyExists("award.detail.title") }
    func testSelectorPlaceholder()      { assertKeyExists("award.detail.selector.placeholder") }
    func testQuantityLabel()            { assertKeyExists("award.detail.quantityLabel") }
    func testPrizeLabel()               { assertKeyExists("award.detail.prizeLabel") }
    func testPrizeNoteEachAward()       { assertKeyExists("award.detail.prizeNote.eachAward") }
    func testPrizeNoteIndividual()      { assertKeyExists("award.detail.prizeNote.individual") }
    func testPrizeNoteTeam()            { assertKeyExists("award.detail.prizeNote.team") }
    func testKudosLabel()               { assertKeyExists("award.detail.kudos.label") }
    func testKudosBadge()               { assertKeyExists("award.detail.kudos.badge") }
    func testKudosCta()                 { assertKeyExists("award.detail.kudos.cta") }
    func testKudosDescription()         { assertKeyExists("award.detail.kudos.description") }
    func testPlaceholderBadgeMissing()  { assertKeyExists("award.detail.placeholder.badgeMissing") }
}

// MARK: - Bundle helper

private extension Bundle {
    /// The principal bundle for the test host application, which contains
    /// Localizable.xcstrings. Mirrors the same helper in KudosLocalizationKeysExistTests.
    var principal: Bundle? {
        guard let identifier = infoDictionary?["CFBundleIdentifier"] as? String,
              identifier.contains("saaTests") else {
            return self
        }
        let url = bundleURL.deletingLastPathComponent().deletingLastPathComponent()
        return Bundle(url: url.appendingPathComponent("saa.app"))
    }
}
