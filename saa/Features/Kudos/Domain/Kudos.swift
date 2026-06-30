import Foundation

// MARK: - KudosID

typealias KudosID = UUID

// MARK: - KudosAuthor

/// Identifies a sender or recipient on a kudos post.
///
/// When `isAnonymous == true` on the parent `Kudos`, the **sender's** `userId`
/// is nil for all users except themselves (revealed by the data layer for
/// "you sent this" rendering). `displayName` falls back to `anonymousNickname`
/// at the mapping layer so this struct never carries an empty name.
/// Tap-to-profile navigation MUST be gated on `userId != nil`.
struct KudosAuthor: Hashable, Sendable {
    /// Nil when the sender is anonymous and the viewer is not the sender.
    let userId: UUID?
    /// Ready-to-display name; never empty — mapper substitutes `anonymousNickname` when needed.
    let displayName: String
    /// E.g. `"CECV10"`. Nil for anonymous senders visible to other users.
    let employeeCode: String?
    /// Remote avatar URL. Nil triggers the generic avatar in the view layer.
    let avatarURL: URL?
    let departmentId: DepartmentID?
    /// Raw kudos-received count; drives `StarTier.from(received:)` in the view layer.
    let kudosReceivedCount: Int
}

// MARK: - Kudos

/// A single peer-recognition post in the Sun*Kudos feature.
///
/// Invariants:
/// - `sender.userId` is nil when `isAnonymous == true` and the current user
///   is not the sender (enforced by the data mapper, not this struct).
/// - `canLike` is false when the current user is the sender (TC_FUN_008);
///   RLS also enforces this server-side.
/// - `heartCount` is the aggregate reaction count, NOT limited to the current user's likes.
struct Kudos: Identifiable, Hashable, Sendable {
    let id: KudosID
    /// The person who sent this kudos.
    let sender: KudosAuthor
    /// The person being recognised.
    let recipient: KudosAuthor
    /// Bold award title displayed on the card (e.g. "IDOL GIỚI TRẺ"). Required.
    let title: String
    /// Body text of the recognition note.
    let message: String
    /// When true the sender identity is hidden per anonymous sending rules.
    let isAnonymous: Bool
    /// Displayed in place of sender name when `isAnonymous == true`.
    let anonymousNickname: String?
    /// Hashtag labels associated with this post, ordered as stored.
    let hashtags: [Hashtag]
    /// Ordered list of image attachments stored in `kudos_attachments` table.
    /// Empty when no images were attached. Migration 20260630000000 dropped
    /// the legacy `kudos.photo_url` column — historical photo URLs were
    /// backfilled into `kudos_attachments` with `sort_order = 0`.
    let attachments: [KudosAttachment]
    /// Aggregate heart-reaction count across all users.
    let heartCount: Int
    /// Whether the currently authenticated user has liked this kudos.
    let isLikedByMe: Bool
    /// False when the current user is the sender — prevents self-liking (TC_FUN_008).
    let canLike: Bool
    /// Deep-link URL for sharing this post externally.
    let shareURL: URL?
    let createdAt: Date
}
