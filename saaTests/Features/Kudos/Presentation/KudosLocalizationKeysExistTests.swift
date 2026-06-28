import XCTest
@testable import saa

// MARK: - KudosLocalizationKeysExistTests
//
// Asserts that every kudos.* key added in Phase 08 is present in
// Localizable.xcstrings and resolves to a non-key value in both vi and en.
//
// Strategy: load each lproj bundle explicitly so locale detection does not
// interfere. `localizedString(forKey:value:table:)` returns the key itself
// when no translation is found. Asserting `resolved != key` catches both
// missing keys and accidental identity translations.

final class KudosLocalizationKeysExistTests: XCTestCase {

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
            // Fall back: xcstrings uses the app bundle directly
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
            viValue,
            key,
            "Missing vi translation for '\(key)'",
            file: file,
            line: line
        )
        let enValue = resolved(key, in: enBundle)
        XCTAssertNotEqual(
            enValue,
            key,
            "Missing en translation for '\(key)'",
            file: file,
            line: line
        )
    }

    // MARK: - kudos.hero.*

    func testHeroTagline() { assertKeyExists("kudos.hero.tagline") }

    // MARK: - kudos.send.*

    func testSendPlaceholder() { assertKeyExists("kudos.send.placeholder") }

    // MARK: - kudos.section.*

    func testSectionSubtitle() { assertKeyExists("kudos.section.subtitle") }
    func testSectionHighlight() { assertKeyExists("kudos.section.highlight") }
    func testSectionSpotlight() { assertKeyExists("kudos.section.spotlight") }
    func testSectionAll() { assertKeyExists("kudos.section.all") }

    // MARK: - kudos.filter.*

    func testFilterHashtag() { assertKeyExists("kudos.filter.hashtag") }
    func testFilterDepartment() { assertKeyExists("kudos.filter.department") }

    // MARK: - kudos.card.*

    func testCardViewDetail() { assertKeyExists("kudos.card.viewDetail") }
    func testCardCopyLink() { assertKeyExists("kudos.card.copyLink") }

    // MARK: - kudos.list.*

    func testListViewAll() { assertKeyExists("kudos.list.viewAll") }
    func testListEmpty() { assertKeyExists("kudos.list.empty") }

    // MARK: - kudos.allKudos.*

    func testAllKudosTitle() { assertKeyExists("kudos.allKudos.title") }

    // MARK: - kudos.recipients.*

    func testRecipientsEmpty() { assertKeyExists("kudos.recipients.empty") }
    func testRecipientsTitle() { assertKeyExists("kudos.recipients.title") }
    func testRecipientsRowReceivedItem() { assertKeyExists("kudos.recipients.row.receivedItem") }
    func testRecipientsRewardSaaShirt() { assertKeyExists("kudos.recipients.reward.saaShirt") }

    // MARK: - kudos.starTier.*

    func testStarTierZero() { assertKeyExists("kudos.starTier.zero") }
    func testStarTierOne() { assertKeyExists("kudos.starTier.one") }
    func testStarTierTwo() { assertKeyExists("kudos.starTier.two") }
    func testStarTierThree() { assertKeyExists("kudos.starTier.three") }

    // MARK: - kudos.stats.*

    func testStatsReceived() { assertKeyExists("kudos.stats.received") }
    func testStatsSent() { assertKeyExists("kudos.stats.sent") }
    func testStatsHearts() { assertKeyExists("kudos.stats.hearts") }
    func testStatsBoxesOpened() { assertKeyExists("kudos.stats.boxesOpened") }
    func testStatsBoxesUnopened() { assertKeyExists("kudos.stats.boxesUnopened") }

    // MARK: - kudos.secretBox.*

    func testSecretBoxOpen() { assertKeyExists("kudos.secretBox.open") }

    // MARK: - kudos.spotlight.*

    func testSpotlightTotalSuffix() { assertKeyExists("kudos.spotlight.totalSuffix") }
    func testSpotlightSearchPlaceholder() { assertKeyExists("kudos.spotlight.search.placeholder") }
    func testSpotlightComingSoon() { assertKeyExists("kudos.spotlight.comingSoon") }

    // MARK: - kudos.toast.*

    func testToastLinkCopied() { assertKeyExists("kudos.toast.linkCopied") }
    func testToastComingSoon() { assertKeyExists("kudos.toast.comingSoon") }
    func testToastLikeFailed() { assertKeyExists("kudos.toast.likeFailed") }

    // MARK: - kudos.anonymous.*

    func testAnonymousFallback() { assertKeyExists("kudos.anonymous.fallback") }

    // MARK: - kudos.error.*

    func testErrorNetwork() { assertKeyExists("kudos.error.network") }
    func testErrorNotAuthenticated() { assertKeyExists("kudos.error.notAuthenticated") }
    func testErrorCannotLikeOwnKudos() { assertKeyExists("kudos.error.cannotLikeOwnKudos") }
    func testErrorAlreadyLiked() { assertKeyExists("kudos.error.alreadyLiked") }
    func testErrorUnknown() { assertKeyExists("kudos.error.unknown") }
    func testErrorCreateDenied() { assertKeyExists("kudos.error.createDenied") }
    func testErrorRecipientSelfBlocked() { assertKeyExists("kudos.error.recipientSelfBlocked") }
    func testErrorAttachmentUploadFailed() { assertKeyExists("kudos.error.attachmentUploadFailed") }
    func testErrorImageTooLarge() { assertKeyExists("kudos.error.imageTooLarge") }
    func testErrorUnsupportedImageType() { assertKeyExists("kudos.error.unsupportedImageType") }

    // MARK: - kudos.retry

    func testRetry() { assertKeyExists("kudos.retry") }
}

// MARK: - Bundle helper

private extension Bundle {
    /// The principal bundle for the test host application, which contains
    /// Localizable.xcstrings. Tests run inside the app process so this
    /// is the same as Bundle.main when TEST_HOST is configured.
    var principal: Bundle? {
        guard let identifier = infoDictionary?["CFBundleIdentifier"] as? String,
              identifier.contains("saaTests") else {
            return self
        }
        // We're in the test bundle — walk up to find the app bundle
        let url = bundleURL.deletingLastPathComponent().deletingLastPathComponent()
        return Bundle(url: url.appendingPathComponent("saa.app"))
    }
}
