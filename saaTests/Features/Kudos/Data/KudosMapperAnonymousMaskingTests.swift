import XCTest
@testable import saa

// MARK: - KudosMapperAnonymousMaskingTests
//
// Gap B3: Tests `KudosMapper.from(dto, currentUserId:, isLikedByMe:)` for anonymous
// masking behavior. Asserts:
// - When dto.is_anonymous=true AND currentUserId != sender_id → sender.displayName =
//   anonymous_nickname (or "Ẩn danh" fallback), userId=nil, employeeCode=nil, avatarURL=nil
// - When dto.is_anonymous=true AND currentUserId == sender_id → sender uses the full
//   profile (full identity)
// - When dto.is_anonymous=false → sender uses profile regardless of current user

final class KudosMapperAnonymousMaskingTests: XCTestCase {

    // MARK: - Fixtures

    private func makeSenderProfile(name: String = "Alice") -> KudosProfileDTO {
        KudosProfileDTO(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: name,
            avatar_url: "https://example.com/alice.jpg",
            email: "alice@example.com",
            department_id: UUID(),
            user_stats: KudosProfileUserStatsDTO(kudos_received_count: 5)
        )
    }

    private func makeRecipientProfile(name: String = "Bob") -> KudosProfileDTO {
        KudosProfileDTO(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: name,
            avatar_url: "https://example.com/bob.jpg",
            email: "bob@example.com",
            department_id: UUID(),
            user_stats: KudosProfileUserStatsDTO(kudos_received_count: 3)
        )
    }

    private func makeDTO(
        is_anonymous: Bool,
        sender_id: UUID,
        anonymous_nickname: String? = nil
    ) -> KudosDTO {
        let sender = makeSenderProfile()
        let recipient = makeRecipientProfile()
        return KudosDTO(
            id: UUID(),
            sender_id: sender_id,
            recipient_id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            title: "Test Kudo",
            message: "Test message",
            is_anonymous: is_anonymous,
            anonymous_nickname: anonymous_nickname,
            status: "published",
            created_at: Date(),
            deleted_at: nil,
            sender: sender,
            recipient: recipient,
            kudos_hashtags: nil,
            kudos_attachments: nil,
            reactions: [KudosReactionCountDTO(count: 5)]
        )
    }

    // MARK: - Non-anonymous kudos (baseline)

    func test_nonAnonymousKudos_senderIsFullyVisible_regardlessOfCurrentUser() {
        let senderId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let currentUserId = UUID()  // Different from sender

        let dto = makeDTO(
            is_anonymous: false,
            sender_id: senderId,
            anonymous_nickname: nil
        )

        let kudos = KudosMapper.from(dto, currentUserId: currentUserId, isLikedByMe: false)

        XCTAssertEqual(kudos.sender.displayName, "Alice", "Non-anonymous sender must show full name")
        XCTAssertEqual(kudos.sender.userId, senderId, "Non-anonymous sender must have userId")
        XCTAssertNotNil(kudos.sender.avatarURL, "Non-anonymous sender must have avatarURL")
    }

    // MARK: - Anonymous kudos, viewed by non-sender

    func test_anonymousKudos_nonSenderViewer_senderIsMasked() {
        let senderId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let currentUserId = UUID()  // Different from sender
        let nickname = "Mysterious Friend"

        let dto = makeDTO(
            is_anonymous: true,
            sender_id: senderId,
            anonymous_nickname: nickname
        )

        let kudos = KudosMapper.from(dto, currentUserId: currentUserId, isLikedByMe: false)

        // Gap B3: Verify masking
        XCTAssertEqual(
            kudos.sender.displayName,
            nickname,
            "Anonymous kudos must show the provided nickname"
        )
        XCTAssertNil(
            kudos.sender.userId,
            "Anonymous masked sender must have nil userId"
        )
        XCTAssertNil(
            kudos.sender.employeeCode,
            "Anonymous masked sender must have nil employeeCode"
        )
        XCTAssertNil(
            kudos.sender.avatarURL,
            "Anonymous masked sender must have nil avatarURL"
        )
        XCTAssertNil(
            kudos.sender.departmentId,
            "Anonymous masked sender must have nil departmentId"
        )
    }

    // MARK: - Anonymous kudos, fallback nickname (nil)

    func test_anonymousKudos_nilNickname_fallsBackToAnonymousLabel() {
        let senderId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let currentUserId = UUID()  // Different from sender

        let dto = makeDTO(
            is_anonymous: true,
            sender_id: senderId,
            anonymous_nickname: nil  // No nickname provided
        )

        let kudos = KudosMapper.from(dto, currentUserId: currentUserId, isLikedByMe: false)

        // Gap B3: Fallback to "Ẩn danh" when nickname is nil
        XCTAssertEqual(
            kudos.sender.displayName,
            "Ẩn danh",
            "Anonymous kudos with nil nickname must use fallback label"
        )
        XCTAssertNil(kudos.sender.userId, "Masked sender must have nil userId")
    }

    // MARK: - Anonymous kudos, viewed by sender (self)

    func test_anonymousKudos_senderViewer_senderIsFullyVisible() {
        let senderId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let currentUserId = senderId  // Same as sender
        let nickname = "Hidden Friend"

        let dto = makeDTO(
            is_anonymous: true,
            sender_id: senderId,
            anonymous_nickname: nickname
        )

        let kudos = KudosMapper.from(dto, currentUserId: currentUserId, isLikedByMe: false)

        // Gap B3: When the current user is the sender, they see the full identity
        // even though the kudo is marked as anonymous to others
        XCTAssertEqual(
            kudos.sender.displayName,
            "Alice",
            "Sender viewing their own anonymous kudo must see full name"
        )
        XCTAssertEqual(
            kudos.sender.userId,
            senderId,
            "Sender viewing their own anonymous kudo must see their userId"
        )
        XCTAssertNotNil(
            kudos.sender.avatarURL,
            "Sender viewing their own anonymous kudo must see their avatarURL"
        )
    }

    // MARK: - Unauthenticated user (currentUserId = nil)

    func test_anonymousKudos_unauthenticatedUser_senderIsMasked() {
        let senderId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let currentUserId: UUID? = nil  // Unauthenticated
        let nickname = "Secret Giver"

        let dto = makeDTO(
            is_anonymous: true,
            sender_id: senderId,
            anonymous_nickname: nickname
        )

        let kudos = KudosMapper.from(dto, currentUserId: currentUserId, isLikedByMe: false)

        // Gap B3: Unauthenticated users see masked sender
        XCTAssertEqual(
            kudos.sender.displayName,
            nickname,
            "Unauthenticated user must see masked sender"
        )
        XCTAssertNil(
            kudos.sender.userId,
            "Unauthenticated user must see masked userId"
        )
    }

    // MARK: - Recipient is always visible

    func test_anonymousKudos_recipientIsAlwaysVisible() {
        let senderId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let currentUserId = UUID()  // Different from sender

        let dto = makeDTO(
            is_anonymous: true,
            sender_id: senderId,
            anonymous_nickname: "Anon"
        )

        let kudos = KudosMapper.from(dto, currentUserId: currentUserId, isLikedByMe: false)

        // Recipient is never masked, regardless of anonymity
        XCTAssertEqual(kudos.recipient.displayName, "Bob", "Recipient must always be visible")
        XCTAssertNotNil(kudos.recipient.userId, "Recipient must have userId")
        XCTAssertNotNil(kudos.recipient.avatarURL, "Recipient must have avatarURL")
    }

    // MARK: - canLike flag respects sender

    func test_anonymousKudos_canLike_falseWhenSenderIsCurrent() {
        let senderId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let currentUserId = senderId  // Same as sender

        let dto = makeDTO(
            is_anonymous: true,
            sender_id: senderId,
            anonymous_nickname: "Self"
        )

        let kudos = KudosMapper.from(dto, currentUserId: currentUserId, isLikedByMe: false)

        XCTAssertFalse(
            kudos.canLike,
            "User cannot like their own kudo, even if anonymous"
        )
    }

    func test_anonymousKudos_canLike_trueWhenNotSender() {
        let senderId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let currentUserId = UUID()  // Different from sender

        let dto = makeDTO(
            is_anonymous: true,
            sender_id: senderId,
            anonymous_nickname: "Other"
        )

        let kudos = KudosMapper.from(dto, currentUserId: currentUserId, isLikedByMe: false)

        XCTAssertTrue(
            kudos.canLike,
            "User can like others' anonymous kudo"
        )
    }

    // MARK: - isAnonymous flag preserved

    func test_anonymousKudos_isAnonymousFlagPreserved() {
        let senderId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let currentUserId = UUID()

        let dto = makeDTO(
            is_anonymous: true,
            sender_id: senderId,
            anonymous_nickname: "Anon"
        )

        let kudos = KudosMapper.from(dto, currentUserId: currentUserId, isLikedByMe: false)

        XCTAssertTrue(
            kudos.isAnonymous,
            "isAnonymous flag must be preserved in the domain entity"
        )
    }
}
