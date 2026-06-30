import XCTest
@testable import saa

// MARK: - KudosMapperTests
//
// Verifies `KudosMapper.from(dto:currentUserId:)` correctly applies:
// - Anonymous masking (strip sender identity when anonymous && not sender)
// - Standard mapping (all fields populate correctly)
// - canLike flag (false when sender == current user)
// - isLikedByMe resolved correctly

final class KudosMapperTests: XCTestCase {

    // MARK: - Fixtures

    private let baseDate = Date(timeIntervalSince1970: 0)
    private let senderId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let recipientId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    private let currentUserId = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
    private let hashtagId = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!

    private func makeSenderProfile() -> KudosProfileDTO {
        KudosProfileDTO(
            id: senderId,
            name: "Alice",
            avatar_url: "https://example.com/alice.jpg",
            email: "alice@example.com",
            department_id: UUID(),
            user_stats: KudosProfileUserStatsDTO(kudos_received_count: 10)
        )
    }

    private func makeRecipientProfile() -> KudosProfileDTO {
        KudosProfileDTO(
            id: recipientId,
            name: "Bob",
            avatar_url: "https://example.com/bob.jpg",
            email: "bob@example.com",
            department_id: UUID(),
            user_stats: KudosProfileUserStatsDTO(kudos_received_count: 5)
        )
    }

    private func makeHashtagJoin(_ tag: String) -> KudosHashtagJoinDTO {
        KudosHashtagJoinDTO(
            hashtag: HashtagDTO(
                id: hashtagId,
                tag: tag
            )
        )
    }

    private func makeKudosDTO(
        sender: KudosProfileDTO? = nil,
        recipient: KudosProfileDTO? = nil,
        isAnonymous: Bool = false,
        anonymousNickname: String? = nil,
        hashtags: [KudosHashtagJoinDTO]? = nil,
        attachments: [KudosAttachmentDTO]? = nil
    ) -> KudosDTO {
        KudosDTO(
            id: UUID(),
            sender_id: senderId,
            recipient_id: recipientId,
            title: "Great Title",
            message: "Great work!",
            is_anonymous: isAnonymous,
            anonymous_nickname: anonymousNickname,
            status: "published",
            created_at: baseDate,
            deleted_at: nil,
            sender: sender,
            recipient: recipient,
            kudos_hashtags: hashtags,
            kudos_attachments: attachments,
            reactions: [KudosReactionCountDTO(count: 3)]
        )
    }

    // MARK: - Standard mapping (non-anonymous)

    func testStandardKudos_allFieldsPopulate() {
        let dto = makeKudosDTO(
            sender: makeSenderProfile(),
            recipient: makeRecipientProfile(),
            hashtags: [makeHashtagJoin("#teamwork")]
        )

        let kudos = KudosMapper.from(
            dto,
            currentUserId: currentUserId,
            isLikedByMe: false
        )

        XCTAssertEqual(kudos.sender.userId, senderId)
        XCTAssertEqual(kudos.sender.displayName, "Alice")
        XCTAssertEqual(kudos.sender.avatarURL?.absoluteString, "https://example.com/alice.jpg")
        XCTAssertEqual(kudos.sender.kudosReceivedCount, 10)

        XCTAssertEqual(kudos.recipient.userId, recipientId)
        XCTAssertEqual(kudos.recipient.displayName, "Bob")

        XCTAssertEqual(kudos.message, "Great work!")
        XCTAssertEqual(kudos.heartCount, 3)
        XCTAssertFalse(kudos.isLikedByMe)
        XCTAssertTrue(kudos.canLike)  // sender != current user
        XCTAssertEqual(kudos.hashtags.count, 1)
        XCTAssertEqual(kudos.hashtags.first?.tag, "#teamwork")
    }

    // MARK: - Anonymous masking (not sender)

    func testAnonymousKudos_notSender_masksIdentity() {
        let dto = makeKudosDTO(
            sender: makeSenderProfile(),
            recipient: makeRecipientProfile(),
            isAnonymous: true,
            anonymousNickname: "Admirer"
        )

        let kudos = KudosMapper.from(
            dto,
            currentUserId: currentUserId,  // different from senderId
            isLikedByMe: false
        )

        XCTAssertNil(kudos.sender.userId)  // masked
        XCTAssertEqual(kudos.sender.displayName, "Admirer")
        XCTAssertNil(kudos.sender.avatarURL)  // masked
        XCTAssertEqual(kudos.sender.kudosReceivedCount, 0)  // masking resets count
        XCTAssertEqual(kudos.isAnonymous, true)
    }

    // MARK: - Anonymous masking (sender reveals identity to self)

    func testAnonymousKudos_isSender_revealsIdentity() {
        let dto = makeKudosDTO(
            sender: makeSenderProfile(),
            recipient: makeRecipientProfile(),
            isAnonymous: true,
            anonymousNickname: "Admirer"
        )

        let kudos = KudosMapper.from(
            dto,
            currentUserId: senderId,  // SAME as senderId — sender viewing own kudos
            isLikedByMe: true
        )

        XCTAssertEqual(kudos.sender.userId, senderId)  // revealed
        XCTAssertEqual(kudos.sender.displayName, "Alice")  // real name
        XCTAssertNotNil(kudos.sender.avatarURL)  // revealed
        XCTAssertEqual(kudos.sender.kudosReceivedCount, 10)  // real count
        XCTAssertEqual(kudos.isAnonymous, true)  // still marked anonymous
    }

    // MARK: - Anonymous masking fallback (nil nickname)

    func testAnonymousKudos_nilNickname_usesFallback() {
        let dto = makeKudosDTO(
            sender: makeSenderProfile(),
            recipient: makeRecipientProfile(),
            isAnonymous: true,
            anonymousNickname: nil  // nil → use fallback
        )

        let kudos = KudosMapper.from(
            dto,
            currentUserId: currentUserId,
            isLikedByMe: false
        )

        XCTAssertEqual(kudos.sender.displayName, "Ẩn danh")  // fallback
    }

    // MARK: - isLikedByMe flag

    func testIsLikedByMe_resolvedCorrectly() {
        let dto = makeKudosDTO(sender: makeSenderProfile(), recipient: makeRecipientProfile())

        let liked = KudosMapper.from(dto, currentUserId: currentUserId, isLikedByMe: true)
        XCTAssertTrue(liked.isLikedByMe)

        let notLiked = KudosMapper.from(dto, currentUserId: currentUserId, isLikedByMe: false)
        XCTAssertFalse(notLiked.isLikedByMe)
    }

    // MARK: - canLike flag (false when sender == current user)

    func testCanLike_falseWhenSenderIsCurrentUser() {
        let dto = makeKudosDTO(sender: makeSenderProfile(), recipient: makeRecipientProfile())

        let kudos = KudosMapper.from(
            dto,
            currentUserId: senderId,  // SAME as sender
            isLikedByMe: false
        )

        XCTAssertFalse(kudos.canLike)
    }

    func testCanLike_trueWhenSenderIsNotCurrentUser() {
        let dto = makeKudosDTO(sender: makeSenderProfile(), recipient: makeRecipientProfile())

        let kudos = KudosMapper.from(
            dto,
            currentUserId: currentUserId,  // different from sender
            isLikedByMe: false
        )

        XCTAssertTrue(kudos.canLike)
    }

    // MARK: - Empty hashtags list

    func testEmptyHashtags_mapsToEmptyArray() {
        let dto = makeKudosDTO(
            sender: makeSenderProfile(),
            recipient: makeRecipientProfile(),
            hashtags: []
        )

        let kudos = KudosMapper.from(dto, currentUserId: currentUserId, isLikedByMe: false)
        XCTAssertEqual(kudos.hashtags.count, 0)
    }

    // MARK: - user_stats nested decode (HIGH-2)

    /// Verifies that kudosReceivedCount is correctly read from the nested
    /// KudosProfileUserStatsDTO shape and StarTier derives correctly.
    func testNestedUserStats_kudosReceivedCount_derivesStarTier() {
        // Profile with 10 kudos_received — StarTier.one threshold
        let senderProfile = KudosProfileDTO(
            id: senderId,
            name: "Alice",
            avatar_url: nil,
            email: "alice@example.com",
            department_id: nil,
            user_stats: KudosProfileUserStatsDTO(kudos_received_count: 10)
        )
        let dto = makeKudosDTO(sender: senderProfile, recipient: makeRecipientProfile())

        let kudos = KudosMapper.from(dto, currentUserId: currentUserId, isLikedByMe: false)

        XCTAssertEqual(kudos.sender.kudosReceivedCount, 10)
        XCTAssertEqual(StarTier.from(received: kudos.sender.kudosReceivedCount), .one)
    }

    /// Verifies nil user_stats falls back to 0 kudosReceivedCount (StarTier.zero).
    func testNestedUserStats_nilUserStats_fallsBackToZero() {
        let profileWithoutStats = KudosProfileDTO(
            id: senderId,
            name: "Alice",
            avatar_url: nil,
            email: "alice@example.com",
            department_id: nil,
            user_stats: nil
        )
        let dto = makeKudosDTO(sender: profileWithoutStats, recipient: makeRecipientProfile())

        let kudos = KudosMapper.from(dto, currentUserId: currentUserId, isLikedByMe: false)

        XCTAssertEqual(kudos.sender.kudosReceivedCount, 0)
        XCTAssertEqual(StarTier.from(received: kudos.sender.kudosReceivedCount), .zero)
    }
}
