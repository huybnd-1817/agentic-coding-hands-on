import Foundation

/// Pure value types for the Kudos card UI layer. Production code maps from
/// the Domain `Kudos` entity via `KudosCardAdapter`. `hashtags` carries the
/// tag string without the leading `#` — the view prepends it.

// MARK: - Typealias

typealias KudosCardID = UUID

// MARK: - KudosCardData

struct KudosCardData: Identifiable, Hashable {
    let id: KudosCardID
    /// Drives the "Người gửi ẩn danh" subtitle. Defaulted so existing call
    /// sites compile unchanged.
    var senderIsAnonymous: Bool = false
    let senderName: String
    let senderCode: String
    let senderStarTier: StarTier
    let senderAvatarURL: URL?
    let recipientName: String
    let recipientCode: String
    let recipientStarTier: StarTier
    let recipientAvatarURL: URL?
    /// Pre-formatted "HH:mm - MM/dd/yyyy".
    let timestampText: String
    let title: String
    let body: String
    /// No leading `#` — view prepends it.
    let hashtags: [String]
    let heartCount: Int
    var isLikedByMe: Bool
    /// False when the current user is the sender (TC_FUN_008).
    let canLike: Bool
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
            senderStarTier: .one,
            senderAvatarURL: nil,
            recipientName: "Dương Xuân Huỳnh...",
            recipientCode: "CECV10",
            recipientStarTier: .three,
            recipientAvatarURL: nil,
            timestampText: "10:00 - 10/30/2025",
            title: "IDOL GIỚI TRẺ",
            body: "Cảm ơn người em bình thường nhưng phi thường :D Cảm ơn sự chăm chỉ, cần mẫn của em đã tạo động lực rất lớn cho mọi người trong team.",
            hashtags: ["Dedicated", "Inspiring", "Hardworking"],
            heartCount: 1000,
            isLikedByMe: false,
            canLike: true
        ),
        KudosCardData(
            id: UUID(),
            senderName: "Nguyễn Văn Quy",
            senderCode: "HANV05",
            senderStarTier: .one,
            senderAvatarURL: nil,
            recipientName: "Đỗ Hoàng Hiệp",
            recipientCode: "HANV02",
            recipientStarTier: .zero,
            recipientAvatarURL: nil,
            timestampText: "09:00 - 10/28/2025",
            title: "NGÔI SAO TEAM",
            body: "Em luôn sẵn sàng hỗ trợ và chia sẻ kiến thức cho cả team. Sự nhiệt tình và tinh thần trách nhiệm của em là tấm gương cho tất cả mọi người.",
            hashtags: ["TeamPlayer", "Supportive", "Dedicated"],
            heartCount: 750,
            isLikedByMe: true,
            canLike: true
        ),
        KudosCardData(
            id: UUID(),
            senderName: "Dương Thúy An",
            senderCode: "HCMV08",
            senderStarTier: .three,
            senderAvatarURL: nil,
            recipientName: "Mai Phương Thúy",
            recipientCode: "HCMV12",
            recipientStarTier: .one,
            recipientAvatarURL: nil,
            timestampText: "14:30 - 10/25/2025",
            title: "BỨT PHÁ XUẤT SẮC",
            body: "Chị đã làm việc không mệt mỏi để hoàn thành dự án đúng deadline trong bối cảnh rất nhiều thách thức. Cả team rất tự hào về chị.",
            hashtags: ["Excellence", "Breakthrough", "Inspiring", "Dedicated", "Teamwork", "Leadership", "Innovation"],
            heartCount: 520,
            isLikedByMe: false,
            // Demo: self-sent kudos — heart disabled per TC_FUN_008.
            canLike: false
        ),
        KudosCardData(
            id: UUID(),
            senderName: "Nguyễn Hoàng Linh",
            senderCode: "HANV15",
            senderStarTier: .zero,
            senderAvatarURL: nil,
            recipientName: "Nguyễn Bá Chức",
            recipientCode: "HANV09",
            recipientStarTier: .two,
            recipientAvatarURL: nil,
            timestampText: "11:00 - 10/22/2025",
            title: "ANH HÙNG THẦm LẶNG",
            body: "Anh luôn âm thầm giải quyết các vấn đề kỹ thuật phức tạp mà không kêu ca. Sự chuyên nghiệp và kiên nhẫn của anh giúp cả team tiến về phía trước.",
            hashtags: ["Dedicated", "Technical", "Silent Hero"],
            heartCount: 300,
            isLikedByMe: false,
            canLike: true
        ),
        KudosCardData(
            id: UUID(),
            senderName: "Lê Kiều Trang",
            senderCode: "HCMV20",
            senderStarTier: .one,
            senderAvatarURL: nil,
            recipientName: "Nguyễn Văn Quy",
            recipientCode: "HANV05",
            recipientStarTier: .three,
            recipientAvatarURL: nil,
            timestampText: "16:00 - 10/20/2025",
            title: "MENTOR TUYỆT VỜI",
            body: "Cảm ơn anh đã luôn hướng dẫn và chia sẻ kinh nghiệm một cách nhiệt tình. Nhờ có anh mà em hiểu được rất nhiều về nghề và về cách làm việc hiệu quả.",
            hashtags: ["Mentor", "Leadership", "Inspiring"],
            heartCount: 890,
            isLikedByMe: true,
            canLike: true
        )
    ]
}
