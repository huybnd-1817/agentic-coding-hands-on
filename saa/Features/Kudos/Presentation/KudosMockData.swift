#if DEBUG
import Foundation

// MARK: - KudosMockData

/// Static preview fixtures for `KudosViewContainer` and `KudosViewModel` previews.
///
/// Uses the same deterministic `UUID`s as `MockKudosRepository` so snapshot tests
/// produce stable output. This enum is stripped from release builds via `#if DEBUG`.
enum KudosMockData {

    // MARK: - Shared authors

    static let senderA = KudosAuthor(
        userId: UUID(uuidString: "aaaaaaaa-0000-0000-0000-000000000001")!,
        displayName: "Huỳnh Dương Xuân",
        employeeCode: "CECV10",
        avatarURL: nil,
        departmentId: UUID(uuidString: "dddddddd-0000-0000-0000-000000000001")!,
        kudosReceivedCount: 42
    )

    static let recipientA = KudosAuthor(
        userId: UUID(uuidString: "bbbbbbbb-0000-0000-0000-000000000002")!,
        displayName: "Dương Xuân Huỳnh",
        employeeCode: "HANV05",
        avatarURL: nil,
        departmentId: UUID(uuidString: "dddddddd-0000-0000-0000-000000000002")!,
        kudosReceivedCount: 25
    )

    // MARK: - Hashtags & departments

    static let hashtags: [Hashtag] = [
        Hashtag(id: UUID(uuidString: "eeeeeeee-0000-0000-0000-000000000001")!, tag: "#Dedicated"),
        Hashtag(id: UUID(uuidString: "eeeeeeee-0000-0000-0000-000000000002")!, tag: "#Inspiring"),
        Hashtag(id: UUID(uuidString: "eeeeeeee-0000-0000-0000-000000000003")!, tag: "#Hardworking"),
        Hashtag(id: UUID(uuidString: "eeeeeeee-0000-0000-0000-000000000004")!, tag: "#TeamPlayer"),
        Hashtag(id: UUID(uuidString: "eeeeeeee-0000-0000-0000-000000000005")!, tag: "#Excellence")
    ]

    static let departments: [Department] = [
        Department(id: UUID(uuidString: "dddddddd-0000-0000-0000-000000000001")!, code: "CEV1", name: "CEV1 - Customer Experience Vietnam 1"),
        Department(id: UUID(uuidString: "dddddddd-0000-0000-0000-000000000002")!, code: "HAN",  name: "HAN - Hanoi Division"),
        Department(id: UUID(uuidString: "dddddddd-0000-0000-0000-000000000003")!, code: "HCM",  name: "HCM - Ho Chi Minh Division")
    ]

    // MARK: - Kudos items

    static let kudosList: [Kudos] = [
        Kudos(
            id: UUID(uuidString: "cccccccc-0000-0000-0000-000000000001")!,
            sender: senderA,
            recipient: recipientA,
            title: "IDOL GIỚI TRẺ",
            message: "Cảm ơn người em bình thường nhưng phi thường :D Cảm ơn sự chăm chỉ, cần mẫn của em đã tạo động lực rất lớn cho mọi người trong team.",
            isAnonymous: false,
            anonymousNickname: nil,
            hashtags: Array(hashtags.prefix(3)),
            attachments: [],
            heartCount: 1000,
            isLikedByMe: false,
            canLike: true,
            shareURL: nil,
            createdAt: Date(timeIntervalSince1970: 1_730_000_000)
        ),
        Kudos(
            id: UUID(uuidString: "cccccccc-0000-0000-0000-000000000002")!,
            sender: recipientA,
            recipient: senderA,
            title: "NGÔI SAO TEAM",
            message: "Em luôn sẵn sàng hỗ trợ và chia sẻ kiến thức cho cả team.",
            isAnonymous: false,
            anonymousNickname: nil,
            hashtags: Array(hashtags.suffix(2)),
            attachments: [],
            heartCount: 750,
            isLikedByMe: true,
            canLike: false,
            shareURL: nil,
            createdAt: Date(timeIntervalSince1970: 1_729_900_000)
        )
    ]

    // MARK: - Stats

    static let stats = UserStats(
        userId: UUID(uuidString: "aaaaaaaa-0000-0000-0000-000000000001")!,
        kudosReceivedCount: 25,
        kudosSentCount: 12,
        kudosHeartsReceived: 340,
        secretBoxesOpened: 3,
        secretBoxesUnopened: 2,
        updatedAt: Date(timeIntervalSince1970: 1_730_000_000)
    )

    // MARK: - Event bonus (active)

    static let activeBonus = EventBonus(
        id: UUID(uuidString: "ffffffff-0000-0000-0000-000000000001")!,
        startsAt: Date(timeIntervalSince1970: 0),
        endsAt: Date(timeIntervalSinceNow: 86_400),
        multiplier: 2,
        label: "Double Heart Day"
    )

    // MARK: - Assembled snapshot

    /// A fully-populated `KudosScreenSnapshot` for use in `KudosViewContainer` previews.
    static let sample = KudosScreenSnapshot(
        highlights: kudosList,
        feed: kudosList,
        hashtags: hashtags,
        departments: departments,
        stats: stats,
        topRecipients: [senderA, recipientA],
        activeBonus: activeBonus
    )
}
#endif
