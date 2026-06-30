import Foundation

// MARK: - KudosID

typealias KudosID = UUID

// MARK: - KudosAuthor

/// Sender or recipient on a kudos post. When `Kudos.isAnonymous` and the
/// viewer is not the sender, the mapper nils out `userId` and substitutes
/// `anonymousNickname` for `displayName` — tap-to-profile MUST gate on
/// `userId != nil`.
struct KudosAuthor: Hashable, Sendable {
    /// Nil when the sender is anonymous and the viewer is not the sender.
    let userId: UUID?
    /// Never empty — mapper substitutes `anonymousNickname` when needed.
    let displayName: String
    /// Nil for masked anonymous senders.
    let employeeCode: String?
    /// Nil triggers the generic avatar in the view layer.
    let avatarURL: URL?
    let departmentId: DepartmentID?
    /// Drives `StarTier.from(received:)`.
    let kudosReceivedCount: Int
}

// MARK: - Kudos

/// Peer-recognition post.
/// Invariants: `sender.userId` is nil when masked-anonymous (enforced by
/// mapper); `canLike` is false when the current user is the sender
/// (TC_FUN_008, also enforced by RLS); `heartCount` is global.
struct Kudos: Identifiable, Hashable, Sendable {
    let id: KudosID
    let sender: KudosAuthor
    let recipient: KudosAuthor
    /// Bold award title (e.g. "IDOL GIỚI TRẺ").
    let title: String
    let message: String
    let isAnonymous: Bool
    /// Substituted for sender name when `isAnonymous == true`.
    let anonymousNickname: String?
    let hashtags: [Hashtag]
    /// Ordered images from `kudos_attachments`. Legacy `kudos.photo_url`
    /// values were backfilled here (migration 20260630000000).
    let attachments: [KudosAttachment]
    /// Aggregate heart count across all users.
    let heartCount: Int
    let isLikedByMe: Bool
    /// False when current user is the sender (TC_FUN_008).
    let canLike: Bool
    let shareURL: URL?
    let createdAt: Date
}
