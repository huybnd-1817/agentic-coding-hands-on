import XCTest
@testable import saa

// MARK: - CreateKudoLocalizationKeysExistTests
//
// Asserts that every kudos.create.* key added in Phase 08 is present in
// Localizable.xcstrings and resolves to a non-key value in both vi and en.
//
// Strategy: load each lproj bundle explicitly so locale detection does not
// interfere. `localizedString(forKey:value:table:)` returns the key itself
// when no translation is found. Asserting `resolved != key` catches both
// missing keys and accidental identity translations.

final class CreateKudoLocalizationKeysExistTests: XCTestCase {

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

    // MARK: - Navigation / Header

    func testTitleNav() { assertKeyExists("kudos.create.title.nav") }
    func testHeader() { assertKeyExists("kudos.create.header") }

    // MARK: - Recipient

    func testRecipientLabel() { assertKeyExists("kudos.create.recipient.label") }
    func testRecipientPlaceholder() { assertKeyExists("kudos.create.recipient.placeholder") }
    func testRecipientEmpty() { assertKeyExists("kudos.create.recipient.empty") }

    // MARK: - Title

    func testTitleLabel() { assertKeyExists("kudos.create.title.label") }
    func testTitlePlaceholder() { assertKeyExists("kudos.create.title.placeholder") }
    func testTitleHint() { assertKeyExists("kudos.create.title.hint") }

    // MARK: - Standards

    func testStandardsLink() { assertKeyExists("kudos.create.standards.link") }

    // MARK: - Message

    func testMessagePlaceholder() { assertKeyExists("kudos.create.message.placeholder") }
    func testMessageHint() { assertKeyExists("kudos.create.message.hint") }

    // MARK: - Hashtag

    func testHashtagLabel() { assertKeyExists("kudos.create.hashtag.label") }
    func testHashtagAdd() { assertKeyExists("kudos.create.hashtag.add") }

    // MARK: - Image

    func testImageLabel() { assertKeyExists("kudos.create.image.label") }
    func testImageAdd() { assertKeyExists("kudos.create.image.add") }

    // MARK: - Anonymous

    func testAnonymousToggle() { assertKeyExists("kudos.create.anonymous.toggle") }
    func testAnonymousNicknameLabel() { assertKeyExists("kudos.create.anonymous.nickname.label") }
    func testAnonymousNicknamePlaceholder() { assertKeyExists("kudos.create.anonymous.nickname.placeholder") }

    // MARK: - Actions

    func testActionCancel() { assertKeyExists("kudos.create.action.cancel") }
    func testActionSend() { assertKeyExists("kudos.create.action.send") }

    // MARK: - Cancel confirmation dialog

    func testCancelConfirmTitle() { assertKeyExists("kudos.create.cancel.confirm.title") }
    func testCancelConfirmBody() { assertKeyExists("kudos.create.cancel.confirm.body") }
    func testCancelConfirmDiscard() { assertKeyExists("kudos.create.cancel.confirm.discard") }
    func testCancelConfirmKeep() { assertKeyExists("kudos.create.cancel.confirm.keep") }

    // MARK: - Toast messages

    func testToastSuccess() { assertKeyExists("kudos.create.toast.success") }
    func testToastErrorNetwork() { assertKeyExists("kudos.create.toast.error.network") }
    func testToastErrorGeneric() { assertKeyExists("kudos.create.toast.error.generic") }
    func testToastStandardsComing() { assertKeyExists("kudos.create.toast.standards.coming") }

    // MARK: - Validation errors (CreateKudoFieldError.localizedKey)

    func testErrorRecipientRequired() { assertKeyExists("kudos.create.error.recipientRequired") }
    func testErrorCannotSendToSelf() { assertKeyExists("kudos.create.error.cannotSendToSelf") }
    func testErrorTitleRequired() { assertKeyExists("kudos.create.error.titleRequired") }
    func testErrorTitleTooLong() { assertKeyExists("kudos.create.error.titleTooLong") }
    func testErrorMessageRequired() { assertKeyExists("kudos.create.error.messageRequired") }
    func testErrorMessageTooLong() { assertKeyExists("kudos.create.error.messageTooLong") }
    func testErrorMessageWhitespaceOnly() { assertKeyExists("kudos.create.error.messageWhitespaceOnly") }
    func testErrorHashtagsRequired() { assertKeyExists("kudos.create.error.hashtagsRequired") }
    func testErrorHashtagsTooMany() { assertKeyExists("kudos.create.error.hashtagsTooMany") }
    func testErrorImagesTooMany() { assertKeyExists("kudos.create.error.imagesTooMany") }
    func testErrorImageTooLarge() { assertKeyExists("kudos.create.error.imageTooLarge") }
    func testErrorUnsupportedImageType() { assertKeyExists("kudos.create.error.unsupportedImageType") }
    func testErrorNicknameRequired() { assertKeyExists("kudos.create.error.nicknameRequired") }
    func testErrorNicknameTooLong() { assertKeyExists("kudos.create.error.nicknameTooLong") }

    // MARK: - localizedKey mapping (CreateKudoFieldError)

    func testLocalizedKeyMappingCoversAllCases() {
        // Each CreateKudoFieldError case must return a key starting with "kudos.create.error."
        let prefix = "kudos.create.error."
        let cases: [CreateKudoFieldError] = [
            .recipientRequired, .cannotSendToSelf,
            .titleRequired, .titleTooLong,
            .messageRequired, .messageWhitespaceOnly, .messageTooLong,
            .hashtagsRequired, .hashtagsTooMany,
            .imagesTooMany, .imageTooLarge, .unsupportedImageType,
            .nicknameRequired, .nicknameTooLong
        ]
        for error in cases {
            XCTAssertTrue(
                error.localizedKey.hasPrefix(prefix),
                "localizedKey '\(error.localizedKey)' does not start with '\(prefix)'"
            )
        }
    }
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
