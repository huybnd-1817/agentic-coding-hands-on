import XCTest
@testable import saa

// MARK: - LocalizationKeysExistTests
//
// Asserts that every home.* and accessDenied.* key added in Phase 05 is
// present in Localizable.xcstrings and resolves to a non-key value.
//
// Strategy: `String(localized:)` returns the key itself when no translation
// is found. Asserting `resolved != key` catches both missing keys and
// accidental identity translations.

final class LocalizationKeysExistTests: XCTestCase {

    // MARK: - Helpers

    /// Resolve a key against the bundle that contains Localizable.xcstrings.
    private func resolved(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .main)
    }

    private func assertKeyExists(_ key: String, file: StaticString = #file, line: UInt = #line) {
        let value = resolved(key)
        XCTAssertNotEqual(
            value,
            key,
            "Localization key '\(key)' is missing or not translated (resolved to itself).",
            file: file,
            line: line
        )
    }

    // MARK: - accessDenied.*

    func testAccessDeniedTitle() { assertKeyExists("accessDenied.title") }
    func testAccessDeniedMessage() { assertKeyExists("accessDenied.message") }
    func testAccessDeniedSignOut() { assertKeyExists("accessDenied.signOut") }

    // MARK: - home.header.*

    func testHeaderSearchAccessibility() { assertKeyExists("home.header.search.accessibility") }
    func testHeaderNotificationsAccessibility() { assertKeyExists("home.header.notifications.accessibility") }

    // MARK: - home.hero.*

    func testHeroComingSoon() { assertKeyExists("home.hero.comingSoon") }
    func testHeroDays() { assertKeyExists("home.hero.days") }
    func testHeroHours() { assertKeyExists("home.hero.hours") }
    func testHeroMinutes() { assertKeyExists("home.hero.minutes") }
    func testHeroDateLabel() { assertKeyExists("home.hero.dateLabel") }
    func testHeroVenueLabel() { assertKeyExists("home.hero.venueLabel") }
    func testHeroLivestreamNote() { assertKeyExists("home.hero.livestreamNote") }
    func testHeroAboutAward() { assertKeyExists("home.hero.aboutAward") }
    func testHeroAboutKudos() { assertKeyExists("home.hero.aboutKudos") }

    // MARK: - home.theme.*

    func testThemeBody() { assertKeyExists("home.theme.body") }

    // MARK: - home.awards.*

    func testAwardsEventLabel() { assertKeyExists("home.awards.eventLabel") }
    func testAwardsSectionTitle() { assertKeyExists("home.awards.sectionTitle") }
    func testAwardsDetails() { assertKeyExists("home.awards.details") }
    func testAwardsEmpty() { assertKeyExists("home.awards.empty") }
    func testAwardsError() { assertKeyExists("home.awards.error") }
    func testAwardsRetry() { assertKeyExists("home.awards.retry") }

    // MARK: - home.kudos.*

    func testKudosEyebrow() { assertKeyExists("home.kudos.eyebrow") }
    func testKudosSectionTitle() { assertKeyExists("home.kudos.sectionTitle") }
    func testKudosNewBadge() { assertKeyExists("home.kudos.newBadge") }
    func testKudosBody() { assertKeyExists("home.kudos.body") }
    func testKudosDetails() { assertKeyExists("home.kudos.details") }

    // MARK: - home.nav.*

    func testNavHome() { assertKeyExists("home.nav.home") }
    func testNavAwards() { assertKeyExists("home.nav.awards") }
    func testNavKudos() { assertKeyExists("home.nav.kudos") }
    func testNavProfile() { assertKeyExists("home.nav.profile") }

    // MARK: - home.language.*

    func testLanguageTitle() { assertKeyExists("home.language.title") }

    // MARK: - home.stub.*  (Phase 06 stub destinations)

    func testStubComingSoon() { assertKeyExists("home.stub.comingSoon") }
    func testStubAwardsOverview() { assertKeyExists("home.stub.awardsOverview") }
    func testStubAwardDetail() { assertKeyExists("home.stub.awardDetail") }
    func testStubKudosOverview() { assertKeyExists("home.stub.kudosOverview") }
    func testStubKudosDetail() { assertKeyExists("home.stub.kudosDetail") }
    func testStubKudosFeed() { assertKeyExists("home.stub.kudosFeed") }
    func testStubWriteKudo() { assertKeyExists("home.stub.writeKudo") }
    func testStubSearch() { assertKeyExists("home.stub.search") }
    func testStubNotifications() { assertKeyExists("home.stub.notifications") }
}
