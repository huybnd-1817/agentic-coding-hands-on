import Foundation

/// Pure Domain → UI mapping for `KudosCardData`. Shared by the Kudos tab
/// preview slice and the All Kudos paginated feed so formatter / star-tier /
/// hashtag-strip / avatar fallback logic lives in one place.
enum KudosCardAdapter {

    /// Static so we don't allocate a fresh `DateFormatter` per card (~20 per render).
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm - MM/dd/yyyy"
        formatter.timeZone = TimeZone(identifier: "Asia/Saigon")
        return formatter
    }()

    /// `departments` lookup is used to resolve the avatar `code` label.
    static func cardData(from kudos: Kudos, departments: [UUID: Department]) -> KudosCardData {
        return KudosCardData(
            id: kudos.id,
            senderIsAnonymous: kudos.isAnonymous,
            senderName: kudos.sender.displayName,
            senderCode: codeLabel(for: kudos.sender, departments: departments),
            senderStarTier: StarTier.from(received: kudos.sender.kudosReceivedCount),
            senderAvatarURL: kudos.sender.avatarURL,
            recipientName: kudos.recipient.displayName,
            recipientCode: codeLabel(for: kudos.recipient, departments: departments),
            recipientStarTier: StarTier.from(received: kudos.recipient.kudosReceivedCount),
            recipientAvatarURL: kudos.recipient.avatarURL,
            timestampText: Self.timestampFormatter.string(from: kudos.createdAt),
            title: kudos.title,
            body: kudos.message,
            hashtags: kudos.hashtags.map { $0.tag.hasPrefix("#") ? String($0.tag.dropFirst()) : $0.tag },
            heartCount: kudos.heartCount,
            isLikedByMe: kudos.isLikedByMe,
            canLike: kudos.canLike
        )
    }

    /// Department code (e.g. `"CEV1"`) → employee code → empty.
    static func codeLabel(for author: KudosAuthor, departments: [UUID: Department]) -> String {
        if let departmentId = author.departmentId, let department = departments[departmentId] {
            return department.code
        }
        return author.employeeCode ?? ""
    }

    /// Deterministic by `userId` byte parity so the same author always renders
    /// the same asset across screens.
    static func avatarAsset(for author: KudosAuthor) -> String {
        guard let id = author.userId else { return "kudos-card-avatar-recipient" }
        let lastByte = id.uuid.15
        return lastByte % 2 == 0 ? "kudos-card-avatar-female" : "kudos-card-avatar-male"
    }
}
