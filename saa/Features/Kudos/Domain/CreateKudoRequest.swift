import Foundation

// MARK: - CreateKudoRequest

/// Validated input for creating a new kudos post.
///
/// Constructed by `CreateKudoViewModel` after `CreateKudoValidator.validate(_:)` returns
/// an empty error array. Passed to `KudosRepositoryProtocol.createKudo(_:)` which
/// persists the record and any attachments, then returns the full domain `Kudos`.
///
/// All fields are immutable value types. No Supabase imports — Data layer maps
/// this to its own DTO.
struct CreateKudoRequest: Sendable {

    /// UUID of the user who will receive this kudos.
    /// Must differ from `senderId` (enforced by `CreateKudoValidator`).
    let recipientId: UUID

    /// UUID of the currently authenticated sender.
    /// Injected by the VM from `KudosRepositoryProtocol.currentUserId()`.
    let senderId: UUID

    /// Bold award title displayed on the feed card. 1–100 characters (trimmed).
    let title: String

    /// Body recognition note. 1–1 000 characters (trimmed, non-whitespace-only).
    let message: String

    /// IDs of selected hashtags. 1–5 unique entries.
    let hashtagIds: [HashtagID]

    /// Attachments already uploaded via `KudosImageUploaderProtocol`. 0–5 items.
    /// Uploaded before request creation so this struct is fully value-typed.
    let attachments: [KudosAttachment]

    /// When `true`, sender identity is hidden from other users. Defaults to `false`.
    let isAnonymous: Bool

    /// Display name shown in place of the sender when `isAnonymous == true`.
    /// Required (1–30 chars) when `isAnonymous` is `true`; `nil` otherwise.
    let anonymousNickname: String?

    /// Heart multiplier from the active `EventBonus`. 1 when no bonus is active.
    let multiplier: Int
}
