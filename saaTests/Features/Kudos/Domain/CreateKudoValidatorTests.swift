import XCTest
@testable import saa

// MARK: - CreateKudoValidatorTests
//
// Covers every validation rule in `CreateKudoValidator` (phase-05 validation table).
// Positive cases (valid input → no errors) and negative cases (invalid input → specific error).
// Each test exercises exactly one rule to keep failures diagnostic.

final class CreateKudoValidatorTests: XCTestCase {

    // MARK: - Helpers

    private let senderID    = UUID(uuidString: "aaaaaaaa-0000-0000-0000-000000000001")!
    private let recipientID = UUID(uuidString: "bbbbbbbb-0000-0000-0000-000000000002")!
    private let hashtagID   = UUID(uuidString: "cccccccc-0000-0000-0000-000000000001")!

    /// Returns a fully valid draft — each individual test mutates exactly one field.
    private func validDraft() -> CreateKudoDraft {
        CreateKudoDraft(
            recipientId: recipientID,
            senderId: senderID,
            title: "Great work!",
            message: "Thank you for your dedication.",
            hashtagIds: [hashtagID],
            imageDrafts: [],
            isAnonymous: false,
            anonymousNickname: nil
        )
    }

    private func makeDraft(_ configure: (inout CreateKudoDraft) -> Void) -> CreateKudoDraft {
        var draft = validDraft()
        configure(&draft)
        return draft
    }

    private func makeImageDraft(bytes: Int = 100, contentType: String = "image/jpeg") -> KudosImageDraft {
        KudosImageDraft(data: Data(count: bytes), contentType: contentType)
    }

    // MARK: - Happy Path

    /// A fully-populated valid draft must produce zero errors.
    func test_validate_happyPath_returnsEmpty() {
        let errors = CreateKudoValidator.validate(validDraft())
        XCTAssertTrue(errors.isEmpty, "Valid draft must produce no errors; got: \(errors)")
    }

    /// Anonymous sending with a valid nickname must be accepted.
    func test_validate_anonymous_validNickname_returnsEmpty() {
        let draft = makeDraft {
            $0.isAnonymous = true
            $0.anonymousNickname = "BíẨn"
        }
        let errors = CreateKudoValidator.validate(draft)
        XCTAssertTrue(errors.isEmpty, "Valid anonymous draft must produce no errors; got: \(errors)")
    }

    // MARK: - Recipient

    /// Missing recipient must produce `.recipientRequired`.
    func test_validate_recipient_missing_producesRecipientRequired() {
        let draft = makeDraft { $0.recipientId = nil }
        XCTAssertTrue(CreateKudoValidator.validate(draft).contains(.recipientRequired))
    }

    /// Recipient equal to sender must produce `.cannotSendToSelf`.
    func test_validate_recipient_equalsSDender_producesCannotSendToSelf() {
        let draft = makeDraft { $0.recipientId = senderID }
        XCTAssertTrue(CreateKudoValidator.validate(draft).contains(.cannotSendToSelf))
    }

    // MARK: - Title

    /// Empty title must produce `.titleRequired`.
    func test_validate_title_empty_producesTitleRequired() {
        let draft = makeDraft { $0.title = "" }
        XCTAssertTrue(CreateKudoValidator.validate(draft).contains(.titleRequired))
    }

    /// Whitespace-only title must produce `.titleRequired` (trimmed to empty).
    func test_validate_title_whitespaceOnly_producesTitleRequired() {
        let draft = makeDraft { $0.title = "   " }
        XCTAssertTrue(CreateKudoValidator.validate(draft).contains(.titleRequired))
    }

    /// Title of exactly 100 characters must be accepted.
    func test_validate_title_exactly100Chars_isValid() {
        let draft = makeDraft { $0.title = String(repeating: "A", count: 100) }
        XCTAssertFalse(CreateKudoValidator.validate(draft).contains(.titleRequired))
        XCTAssertFalse(CreateKudoValidator.validate(draft).contains(.titleTooLong))
    }

    /// Title of 101 characters must produce `.titleTooLong`.
    func test_validate_title_101Chars_producesTooLong() {
        let draft = makeDraft { $0.title = String(repeating: "A", count: 101) }
        XCTAssertTrue(CreateKudoValidator.validate(draft).contains(.titleTooLong))
    }

    // MARK: - Message

    /// Empty message must produce `.messageRequired`.
    func test_validate_message_empty_producesMessageRequired() {
        let draft = makeDraft { $0.message = "" }
        XCTAssertTrue(CreateKudoValidator.validate(draft).contains(.messageRequired))
    }

    /// Whitespace-only message must produce `.messageWhitespaceOnly`, not `.messageRequired`.
    func test_validate_message_whitespaceOnly_producesWhitespaceOnly() {
        let draft = makeDraft { $0.message = "   \n\t  " }
        let errors = CreateKudoValidator.validate(draft)
        XCTAssertTrue(errors.contains(.messageWhitespaceOnly),  "Expected .messageWhitespaceOnly")
        XCTAssertFalse(errors.contains(.messageRequired),       "Must NOT produce .messageRequired for whitespace input")
    }

    /// Message of exactly 1 000 characters must be accepted.
    func test_validate_message_exactly1000Chars_isValid() {
        let draft = makeDraft { $0.message = String(repeating: "x", count: 1_000) }
        XCTAssertFalse(CreateKudoValidator.validate(draft).contains(.messageTooLong))
    }

    /// Message of 1 001 characters must produce `.messageTooLong`.
    func test_validate_message_1001Chars_producesTooLong() {
        let draft = makeDraft { $0.message = String(repeating: "x", count: 1_001) }
        XCTAssertTrue(CreateKudoValidator.validate(draft).contains(.messageTooLong))
    }

    // MARK: - Hashtags

    /// No hashtags selected must produce `.hashtagsRequired`.
    func test_validate_hashtags_empty_producesHashtagsRequired() {
        let draft = makeDraft { $0.hashtagIds = [] }
        XCTAssertTrue(CreateKudoValidator.validate(draft).contains(.hashtagsRequired))
    }

    /// Exactly 5 unique hashtags must be accepted.
    func test_validate_hashtags_exactly5_isValid() {
        let ids = (1...5).map { UUID(uuidString: "cccccccc-0000-0000-00\(String(format: "%02d", $0))-000000000001")! }
        let draft = makeDraft { $0.hashtagIds = ids }
        XCTAssertFalse(CreateKudoValidator.validate(draft).contains(.hashtagsTooMany))
        XCTAssertFalse(CreateKudoValidator.validate(draft).contains(.hashtagsRequired))
    }

    /// 6 unique hashtags must produce `.hashtagsTooMany`.
    func test_validate_hashtags_6unique_producesTooMany() {
        let ids = (1...6).map { UUID(uuidString: "cccccccc-0000-0000-00\(String(format: "%02d", $0))-000000000001")! }
        let draft = makeDraft { $0.hashtagIds = ids }
        XCTAssertTrue(CreateKudoValidator.validate(draft).contains(.hashtagsTooMany))
    }

    /// Duplicate hashtag IDs must be de-duplicated before checking the 5-limit.
    func test_validate_hashtags_duplicates_countedOnce() {
        // 3 copies of the same ID → unique count = 1 → must NOT produce .hashtagsTooMany
        let draft = makeDraft { $0.hashtagIds = [hashtagID, hashtagID, hashtagID] }
        XCTAssertFalse(CreateKudoValidator.validate(draft).contains(.hashtagsTooMany))
    }

    // MARK: - Images

    /// 5 valid images must be accepted.
    func test_validate_images_exactly5_isValid() {
        let drafts = (0..<5).map { _ in makeImageDraft() }
        let draft = makeDraft { $0.imageDrafts = drafts }
        XCTAssertFalse(CreateKudoValidator.validate(draft).contains(.imagesTooMany))
    }

    /// 6 images must produce `.imagesTooMany`.
    func test_validate_images_6_producesTooMany() {
        let drafts = (0..<6).map { _ in makeImageDraft() }
        let draft = makeDraft { $0.imageDrafts = drafts }
        XCTAssertTrue(CreateKudoValidator.validate(draft).contains(.imagesTooMany))
    }

    /// An image at exactly 5 MB must be accepted.
    func test_validate_image_exactly5MB_isValid() {
        let fiveMB = 5 * 1024 * 1024
        let draft = makeDraft { $0.imageDrafts = [makeImageDraft(bytes: fiveMB)] }
        XCTAssertFalse(CreateKudoValidator.validate(draft).contains(.imageTooLarge))
    }

    /// An image exceeding 5 MB must produce `.imageTooLarge`.
    func test_validate_image_over5MB_producesImageTooLarge() {
        let over5MB = 5 * 1024 * 1024 + 1
        let draft = makeDraft { $0.imageDrafts = [makeImageDraft(bytes: over5MB)] }
        XCTAssertTrue(CreateKudoValidator.validate(draft).contains(.imageTooLarge))
    }

    /// An image with `image/png` content type must be accepted.
    func test_validate_image_png_isValid() {
        let draft = makeDraft { $0.imageDrafts = [makeImageDraft(contentType: "image/png")] }
        XCTAssertFalse(CreateKudoValidator.validate(draft).contains(.unsupportedImageType))
    }

    /// An image with an unsupported MIME type must produce `.unsupportedImageType`.
    func test_validate_image_gif_producesUnsupportedType() {
        let draft = makeDraft { $0.imageDrafts = [makeImageDraft(contentType: "image/gif")] }
        XCTAssertTrue(CreateKudoValidator.validate(draft).contains(.unsupportedImageType))
    }

    /// Multiple images with different violations each report their error only once.
    func test_validate_images_multipleSizeViolations_reportsOnce() {
        let over5MB = 5 * 1024 * 1024 + 1
        let drafts = [makeImageDraft(bytes: over5MB), makeImageDraft(bytes: over5MB)]
        let draft = makeDraft { $0.imageDrafts = drafts }
        let errors = CreateKudoValidator.validate(draft)
        XCTAssertEqual(errors.filter { $0 == .imageTooLarge }.count, 1,
                       ".imageTooLarge must be reported exactly once even with multiple violations")
    }

    // MARK: - Anonymous Nickname

    /// `isAnonymous == true` with no nickname must produce `.nicknameRequired`.
    func test_validate_anonymous_missingNickname_producesNicknameRequired() {
        let draft = makeDraft {
            $0.isAnonymous = true
            $0.anonymousNickname = nil
        }
        XCTAssertTrue(CreateKudoValidator.validate(draft).contains(.nicknameRequired))
    }

    /// `isAnonymous == true` with whitespace-only nickname must produce `.nicknameRequired`.
    func test_validate_anonymous_whitespaceNickname_producesNicknameRequired() {
        let draft = makeDraft {
            $0.isAnonymous = true
            $0.anonymousNickname = "   "
        }
        XCTAssertTrue(CreateKudoValidator.validate(draft).contains(.nicknameRequired))
    }

    /// Nickname of exactly 30 characters must be accepted.
    func test_validate_anonymous_nickname_exactly30Chars_isValid() {
        let draft = makeDraft {
            $0.isAnonymous = true
            $0.anonymousNickname = String(repeating: "A", count: 30)
        }
        XCTAssertFalse(CreateKudoValidator.validate(draft).contains(.nicknameTooLong))
        XCTAssertFalse(CreateKudoValidator.validate(draft).contains(.nicknameRequired))
    }

    /// Nickname of 31 characters must produce `.nicknameTooLong`.
    func test_validate_anonymous_nickname_31Chars_producesTooLong() {
        let draft = makeDraft {
            $0.isAnonymous = true
            $0.anonymousNickname = String(repeating: "A", count: 31)
        }
        XCTAssertTrue(CreateKudoValidator.validate(draft).contains(.nicknameTooLong))
    }

    /// Nickname rules must NOT apply when `isAnonymous == false`.
    func test_validate_notAnonymous_noNickname_isValid() {
        let draft = makeDraft {
            $0.isAnonymous = false
            $0.anonymousNickname = nil
        }
        let errors = CreateKudoValidator.validate(draft)
        XCTAssertFalse(errors.contains(.nicknameRequired))
        XCTAssertFalse(errors.contains(.nicknameTooLong))
    }

    // MARK: - Multiple Errors

    /// When multiple fields are invalid, all errors are reported in one pass.
    func test_validate_multipleInvalidFields_allErrorsReported() {
        var draft = CreateKudoDraft()
        draft.senderId = senderID
        // recipientId = nil → .recipientRequired
        // title = "" → .titleRequired
        // message = "" → .messageRequired
        // hashtagIds = [] → .hashtagsRequired
        // isAnonymous = false → no nickname errors

        let errors = CreateKudoValidator.validate(draft)
        XCTAssertTrue(errors.contains(.recipientRequired))
        XCTAssertTrue(errors.contains(.titleRequired))
        XCTAssertTrue(errors.contains(.messageRequired))
        XCTAssertTrue(errors.contains(.hashtagsRequired))
        XCTAssertEqual(errors.count, 4, "Expected exactly 4 errors; got: \(errors)")
    }
}
