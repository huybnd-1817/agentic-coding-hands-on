import Foundation

/// Pure Domain → UI mapping for `KudosCardData`. Shared by both `KudosViewContainer`
/// (preview slice of the feed) and `AllKudosViewContainer` (paginated full feed) so
/// the formatter, star-tier derivation, hashtag stripping, and avatar fallback logic
/// live in exactly one place (DRY — development-rules.md).
enum KudosCardAdapter {

    /// Shared timestamp formatter — `HH:mm - MM/dd/yyyy` in `Asia/Saigon`.
    /// Hoisted to a static so each card render does not allocate a fresh
    /// `DateFormatter` (one allocation per call × ~20+ cards per render cycle
    /// was wasteful; reviewer report 260628 m2).
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm - MM/dd/yyyy"
        formatter.timeZone = TimeZone(identifier: "Asia/Saigon")
        return formatter
    }()

    /// Builds the presentation `KudosCardData` from a Domain `Kudos` entity.
    ///
    /// - Parameter departments: lookup keyed by department UUID — used to resolve the
    ///   `code` label shown under each avatar via `codeLabel(for:departments:)`.
    static func cardData(from kudos: Kudos, departments: [UUID: Department]) -> KudosCardData {
        return KudosCardData(
            id: kudos.id,
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

    /// Resolves the `code` slot shown under the avatar to the author's department
    /// code (e.g. `"CEV1"`) — looked up via `departmentId`. Falls back to
    /// `employeeCode`, then to empty so the row still lays out cleanly.
    static func codeLabel(for author: KudosAuthor, departments: [UUID: Department]) -> String {
        if let departmentId = author.departmentId, let department = departments[departmentId] {
            return department.code
        }
        return author.employeeCode ?? ""
    }

    /// Deterministic local-asset fallback for author avatars until `AsyncImage`
    /// lands in a follow-up phase. Picks by `userId` byte parity so the same
    /// author always renders the same asset across screens.
    static func avatarAsset(for author: KudosAuthor) -> String {
        guard let id = author.userId else { return "kudos-card-avatar-recipient" }
        let lastByte = id.uuid.15
        return lastByte % 2 == 0 ? "kudos-card-avatar-female" : "kudos-card-avatar-male"
    }
}
