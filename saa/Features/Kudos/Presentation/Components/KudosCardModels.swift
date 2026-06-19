import Foundation

/// Pure value types for the Kudos card UI layer. No ViewModel, no networking.
///
/// `KudosCardData` carries all display-ready strings and state that `KudosCard`
/// and `KudosHighlightSection` need. Production code will map from a domain
/// entity into this struct; mock data is co-located here via `mockList` for
/// previews and tests.
///
/// Invariants:
/// - `hashtags` is ordered as it appears in the design (red text row).
/// - `heartCount` is raw; formatting (e.g. "1.000") is done by the view.
/// - `isLikedByMe` controls the filled/outline heart state in `KudosCard`.

// MARK: - Typealias

typealias KudosCardID = UUID

// MARK: - KudosCardData

struct KudosCardData: Identifiable, Hashable {
    let id: KudosCardID
    /// Sender display name (e.g. "Huỳnh Dương Xuân...")
    let senderName: String
    /// Sender employee code (e.g. "CECV10")
    let senderCode: String
    /// Sender role badge label (e.g. "Rising Hero")
    let senderRole: String
    /// Asset name for sender avatar `Image("...")`.
    let senderAvatarAssetName: String
    /// Recipient display name (e.g. "Dương Xuân Huỳnh...")
    let recipientName: String
    /// Recipient employee code
    let recipientCode: String
    /// Recipient role badge label (e.g. "Legend Hero")
    let recipientRole: String
    /// Asset name for recipient avatar `Image("...")`.
    let recipientAvatarAssetName: String
    /// Pre-formatted timestamp string (e.g. "10:00 - 10/30/2025")
    let timestampText: String
    /// Gold bold title displayed on the card (e.g. "IDOL GIỚI TRẺ")
    let title: String
    /// Body text of the thank-you note
    let body: String
    /// Ordered hashtag labels without leading '#' — view prepends '#'.
    let hashtags: [String]
    /// Raw heart reaction count
    let heartCount: Int
    /// Whether the current user has liked this kudo
    var isLikedByMe: Bool
}

// MARK: - HashtagOption

struct HashtagOption: Identifiable, Hashable {
    let id: UUID
    let label: String

    init(id: UUID = UUID(), label: String) {
        self.id = id
        self.label = label
    }
}

// MARK: - DepartmentOption

struct DepartmentOption: Identifiable, Hashable {
    let id: UUID
    let label: String

    init(id: UUID = UUID(), label: String) {
        self.id = id
        self.label = label
    }
}

// MARK: - Mock factory

extension KudosCardData {
    /// Sample cards sourced from MoMorph node 6885:9092 and surrounding context.
    /// Used by previews, snapshot tests, and `KudosHighlightSection` preview.
    static let mockList: [KudosCardData] = [
        KudosCardData(
            id: UUID(),
            senderName: "Huỳnh Dương Xuân...",
            senderCode: "CECV10",
            senderRole: "Rising Hero",
            senderAvatarAssetName: "kudos-card-avatar-male",
            recipientName: "Dương Xuân Huỳnh...",
            recipientCode: "CECV10",
            recipientRole: "Legend Hero",
            recipientAvatarAssetName: "kudos-card-avatar-recipient",
            timestampText: "10:00 - 10/30/2025",
            title: "IDOL GIỚI TRẺ",
            body: "Cảm ơn người em bình thường nhưng phi thường :D Cảm ơn sự chăm chỉ, cần mẫn của em đã tạo động lực rất lớn cho mọi người trong team.",
            hashtags: ["Dedicated", "Inspiring", "Hardworking"],
            heartCount: 1000,
            isLikedByMe: false
        ),
        KudosCardData(
            id: UUID(),
            senderName: "Nguyễn Văn Quy",
            senderCode: "HANV05",
            senderRole: "Rising Hero",
            senderAvatarAssetName: "kudos-card-avatar-male",
            recipientName: "Đỗ Hoàng Hiệp",
            recipientCode: "HANV02",
            recipientRole: "Team Player",
            recipientAvatarAssetName: "kudos-card-avatar-female",
            timestampText: "09:00 - 10/28/2025",
            title: "NGÔI SAO TEAM",
            body: "Em luôn sẵn sàng hỗ trợ và chia sẻ kiến thức cho cả team. Sự nhiệt tình và tinh thần trách nhiệm của em là tấm gương cho tất cả mọi người.",
            hashtags: ["TeamPlayer", "Supportive", "Dedicated"],
            heartCount: 750,
            isLikedByMe: true
        ),
        KudosCardData(
            id: UUID(),
            senderName: "Dương Thúy An",
            senderCode: "HCMV08",
            senderRole: "Legend Hero",
            senderAvatarAssetName: "kudos-card-avatar-female",
            recipientName: "Mai Phương Thúy",
            recipientCode: "HCMV12",
            recipientRole: "Rising Hero",
            recipientAvatarAssetName: "kudos-card-avatar-recipient",
            timestampText: "14:30 - 10/25/2025",
            title: "BỨT PHÁ XUẤT SẮC",
            body: "Chị đã làm việc không mệt mỏi để hoàn thành dự án đúng deadline trong bối cảnh rất nhiều thách thức. Cả team rất tự hào về chị.",
            hashtags: ["Excellence", "Breakthrough", "Inspiring"],
            heartCount: 520,
            isLikedByMe: false
        ),
        KudosCardData(
            id: UUID(),
            senderName: "Nguyễn Hoàng Linh",
            senderCode: "HANV15",
            senderRole: "Team Player",
            senderAvatarAssetName: "kudos-card-avatar-male",
            recipientName: "Nguyễn Bá Chức",
            recipientCode: "HANV09",
            recipientRole: "Rising Hero",
            recipientAvatarAssetName: "kudos-card-avatar-recipient",
            timestampText: "11:00 - 10/22/2025",
            title: "ANH HÙNG THẦm LẶNG",
            body: "Anh luôn âm thầm giải quyết các vấn đề kỹ thuật phức tạp mà không kêu ca. Sự chuyên nghiệp và kiên nhẫn của anh giúp cả team tiến về phía trước.",
            hashtags: ["Dedicated", "Technical", "Silent Hero"],
            heartCount: 300,
            isLikedByMe: false
        ),
        KudosCardData(
            id: UUID(),
            senderName: "Lê Kiều Trang",
            senderCode: "HCMV20",
            senderRole: "Rising Hero",
            senderAvatarAssetName: "kudos-card-avatar-female",
            recipientName: "Nguyễn Văn Quy",
            recipientCode: "HANV05",
            recipientRole: "Legend Hero",
            recipientAvatarAssetName: "kudos-card-avatar-male",
            timestampText: "16:00 - 10/20/2025",
            title: "MENTOR TUYỆT VỜI",
            body: "Cảm ơn anh đã luôn hướng dẫn và chia sẻ kinh nghiệm một cách nhiệt tình. Nhờ có anh mà em hiểu được rất nhiều về nghề và về cách làm việc hiệu quả.",
            hashtags: ["Mentor", "Leadership", "Inspiring"],
            heartCount: 890,
            isLikedByMe: true
        )
    ]
}
