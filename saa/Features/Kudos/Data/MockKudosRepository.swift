#if DEBUG
import Foundation

// MARK: - MockKudosRepository

/// In-memory stub implementation of `KudosRepositoryProtocol` for SwiftUI previews
/// and unit test doubles.
///
/// Uses deterministic `UUID`s so snapshot tests produce stable output.
/// NOT wired in production — see `saaApp.swift` composition root which guards
/// repository injection with `#if DEBUG`.
final class MockKudosRepository: KudosRepositoryProtocol, Sendable {

    // MARK: - Fixtures

    private static let senderA = KudosAuthor(
        userId: UUID(uuidString: "aaaaaaaa-0000-0000-0000-000000000001")!,
        displayName: "Huỳnh Dương Xuân",
        employeeCode: "CECV10",
        avatarURL: nil,
        departmentId: UUID(uuidString: "dddddddd-0000-0000-0000-000000000001")!,
        kudosReceivedCount: 42
    )

    private static let recipientA = KudosAuthor(
        userId: UUID(uuidString: "bbbbbbbb-0000-0000-0000-000000000002")!,
        displayName: "Dương Xuân Huỳnh",
        employeeCode: "HANV05",
        avatarURL: nil,
        departmentId: UUID(uuidString: "dddddddd-0000-0000-0000-000000000002")!,
        kudosReceivedCount: 25
    )

    private static let senderB = KudosAuthor(
        userId: UUID(uuidString: "aaaaaaaa-0000-0000-0000-000000000003")!,
        displayName: "Nguyễn Văn Quy",
        employeeCode: "HANV05",
        avatarURL: nil,
        departmentId: UUID(uuidString: "dddddddd-0000-0000-0000-000000000002")!,
        kudosReceivedCount: 15
    )

    private static let hashtags: [Hashtag] = [
        Hashtag(id: UUID(uuidString: "eeeeeeee-0000-0000-0000-000000000001")!, tag: "#Dedicated"),
        Hashtag(id: UUID(uuidString: "eeeeeeee-0000-0000-0000-000000000002")!, tag: "#Inspiring"),
        Hashtag(id: UUID(uuidString: "eeeeeeee-0000-0000-0000-000000000003")!, tag: "#Hardworking"),
        Hashtag(id: UUID(uuidString: "eeeeeeee-0000-0000-0000-000000000004")!, tag: "#TeamPlayer"),
        Hashtag(id: UUID(uuidString: "eeeeeeee-0000-0000-0000-000000000005")!, tag: "#Excellence")
    ]

    private static let departments: [Department] = [
        Department(id: UUID(uuidString: "dddddddd-0000-0000-0000-000000000001")!, code: "CEV1", name: "CEV1 - Customer Experience Vietnam 1"),
        Department(id: UUID(uuidString: "dddddddd-0000-0000-0000-000000000002")!, code: "HAN",  name: "HAN - Hanoi Division"),
        Department(id: UUID(uuidString: "dddddddd-0000-0000-0000-000000000003")!, code: "HCM",  name: "HCM - Ho Chi Minh Division"),
        Department(id: UUID(uuidString: "dddddddd-0000-0000-0000-000000000004")!, code: "DAN",  name: "DAN - Da Nang Division"),
        Department(id: UUID(uuidString: "dddddddd-0000-0000-0000-000000000005")!, code: "R&D",  name: "R&D - Research & Development")
    ]

    private static let kudosFeed: [Kudos] = [
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
            sender: senderB,
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
        ),
        Kudos(
            id: UUID(uuidString: "cccccccc-0000-0000-0000-000000000003")!,
            sender: KudosAuthor(
                userId: nil,
                displayName: "Bí Ẩn",
                employeeCode: nil,
                avatarURL: nil,
                departmentId: nil,
                kudosReceivedCount: 0
            ),
            recipient: recipientA,
            title: "NGƯỜI HÙNG THẦM LẶNG",
            message: "Cảm ơn bạn đã luôn nhiệt tình hỗ trợ mọi người!",
            isAnonymous: true,
            anonymousNickname: "Bí Ẩn",
            hashtags: [hashtags[1]],
            attachments: [],
            heartCount: 320,
            isLikedByMe: false,
            canLike: true,
            shareURL: nil,
            createdAt: Date(timeIntervalSince1970: 1_729_800_000)
        )
    ]

    // MARK: - KudosRepositoryProtocol

    func fetchHighlightKudos(filter: KudosFilter) async throws -> [Kudos] {
        Self.kudosFeed.sorted { $0.heartCount > $1.heartCount }
    }

    func fetchKudosFeed(filter: KudosFilter, page: Int, pageSize: Int) async throws -> [Kudos] {
        let start = page * pageSize
        guard start < Self.kudosFeed.count else { return [] }
        return Array(Self.kudosFeed[start..<min(start + pageSize, Self.kudosFeed.count)])
    }

    func fetchHashtags() async throws -> [Hashtag] {
        Self.hashtags
    }

    func fetchDepartments() async throws -> [Department] {
        Self.departments
    }

    func fetchMyStats() async throws -> UserStats {
        UserStats(
            userId: UUID(uuidString: "aaaaaaaa-0000-0000-0000-000000000001")!,
            kudosReceivedCount: 25,
            kudosSentCount: 12,
            kudosHeartsReceived: 340,
            secretBoxesOpened: 3,
            secretBoxesUnopened: 2,
            updatedAt: Date(timeIntervalSince1970: 1_730_000_000)
        )
    }

    func fetchTopGiftRecipients(limit: Int) async throws -> [KudosAuthor] {
        // Out of scope: replaced when reward_recipients table lands (see plan deferred).
        return []
    }

    func fetchEligibleRecipients() async throws -> [ProfileSummary] {
        [
            ProfileSummary(
                id: UUID(uuidString: "bbbbbbbb-0000-0000-0000-000000000002")!,
                displayName: "Dương Xuân Huỳnh",
                employeeCode: "HANV05",
                avatarURL: nil,
                department: "HAN"
            ),
            ProfileSummary(
                id: UUID(uuidString: "aaaaaaaa-0000-0000-0000-000000000003")!,
                displayName: "Nguyễn Văn Quy",
                employeeCode: "HANV06",
                avatarURL: nil,
                department: "HAN"
            )
        ]
    }

    func fetchActiveEventBonus(now: Date) async throws -> EventBonus? {
        // Return a mock active bonus for preview purposes.
        EventBonus(
            id: UUID(uuidString: "ffffffff-0000-0000-0000-000000000001")!,
            startsAt: Date(timeIntervalSince1970: 0),
            endsAt: Date(timeIntervalSinceNow: 86400),
            multiplier: 2,
            label: "Double Heart Day"
        )
    }

    func likeKudos(kudosId: KudosID, multiplier: Int) async throws -> Bool { true }

    func unlikeKudos(kudosId: KudosID) async throws -> Bool { false }

    func currentUserId() async -> UUID? {
        UUID(uuidString: "aaaaaaaa-0000-0000-0000-000000000001")!
    }

    /// Passthrough — previews don't talk to Supabase Storage, so a parsed URL
    /// is sufficient when one can be constructed.
    func attachmentImageURL(forStoragePath storagePath: String) async -> URL? {
        URL(string: storagePath)
    }

    func createKudo(_ request: CreateKudoRequest) async throws -> Kudos {
        // Stub: return a synthetic kudos for preview purposes.
        Kudos(
            id: UUID(),
            sender: Self.senderA,
            recipient: Self.recipientA,
            title: request.title,
            message: request.message,
            isAnonymous: request.isAnonymous,
            anonymousNickname: request.anonymousNickname,
            hashtags: [],
            attachments: request.attachments,
            heartCount: 0,
            isLikedByMe: false,
            canLike: false,
            shareURL: nil,
            createdAt: Date()
        )
    }
}
#endif
