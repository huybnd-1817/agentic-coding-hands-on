import Foundation

// MARK: - KudosProfileUserStatsDTO

/// Nested `user_stats` sub-join. PostgREST returns embeds as JSON objects
/// (not scalars), so decoding `user_stats(kudos_received_count)` directly as
/// `Int?` raises `DecodingError.typeMismatch` at runtime.
struct KudosProfileUserStatsDTO: Codable, Sendable {

    let kudos_received_count: Int?

    enum CodingKeys: String, CodingKey {
        case kudos_received_count
    }
}

// MARK: - KudosProfileDTO

/// Profile row embedded inside a kudos query. `user_stats` sub-join carries
/// `kudos_received_count` so `KudosMapper` derives `StarTier` without a
/// second fetch. Use `kudosReceivedCount` rather than accessing `user_stats`.
struct KudosProfileDTO: Codable, Sendable {

    let id: UUID
    let name: String?
    let avatar_url: String?
    let email: String
    let department_id: UUID?

    // Joined from user_stats via nested select on the same query.
    // Nil when the user_stats row does not yet exist (new profile, trigger pending).
    let user_stats: KudosProfileUserStatsDTO?

    /// Convenience accessor: extracted from the nested `user_stats` object.
    var kudosReceivedCount: Int { user_stats?.kudos_received_count ?? 0 }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case avatar_url
        case email
        case department_id
        case user_stats
    }
}

// MARK: - KudosAttachmentDTO

/// Join shape for `kudos_attachments(*)`. Rows returned in `sort_order` asc
/// per `kudosSelectClause` in `SupabaseKudosRepository`.
struct KudosAttachmentDTO: Codable, Sendable {

    let id: UUID
    let storage_path: String
    let sort_order: Int
    let content_type: String
    let byte_size: Int

    enum CodingKeys: String, CodingKey {
        case id
        case storage_path
        case sort_order
        case content_type
        case byte_size
    }
}

// MARK: - KudosHashtagJoinDTO

/// Join shape for `kudos_hashtags(hashtag:hashtags(*))` nested select.
struct KudosHashtagJoinDTO: Codable, Sendable {

    let hashtag: HashtagDTO

    enum CodingKeys: String, CodingKey {
        case hashtag
    }
}

// MARK: - KudosReactionCountDTO

/// Aggregate shape for `kudos_reactions(count)` — PostgREST returns
/// `[{"count": N}]`; we take `.first?.count`.
struct KudosReactionCountDTO: Codable, Sendable {

    let count: Int

    enum CodingKeys: String, CodingKey {
        case count
    }
}

// MARK: - KudosDTO

/// Wire format for `public.kudos` + joins (sender/recipient profiles,
/// `kudos_hashtags`, `kudos_attachments`, `reactions` aggregate). `liked_by_me`
/// is resolved client-side per batch by the repository. `photo_url` was
/// dropped (migration 20260630000000) and backfilled into `kudos_attachments`.
struct KudosDTO: Codable, Sendable {

    let id: UUID
    let sender_id: UUID
    let recipient_id: UUID
    let title: String
    let message: String
    let is_anonymous: Bool
    let anonymous_nickname: String?
    let status: String
    let created_at: Date
    let deleted_at: Date?

    // Joined relations (nil when select alias mismatches or join absent).
    let sender: KudosProfileDTO?
    let recipient: KudosProfileDTO?
    let kudos_hashtags: [KudosHashtagJoinDTO]?
    /// Nil when join absent; empty when no attachments exist for the kudos.
    let kudos_attachments: [KudosAttachmentDTO]?

    /// Nested aggregate. Repository falls back to a separate count query if nil.
    let reactions: [KudosReactionCountDTO]?

    enum CodingKeys: String, CodingKey {
        case id
        case sender_id
        case recipient_id
        case title
        case message
        case is_anonymous
        case anonymous_nickname
        case status
        case created_at
        case deleted_at
        case sender
        case recipient
        case kudos_hashtags
        case kudos_attachments
        case reactions
    }

    /// Total heart count from the nested aggregate; 0 signals fallback needed.
    var heartCount: Int { reactions?.first?.count ?? 0 }
}
