import Foundation

// MARK: - KudosProfileUserStatsDTO

/// Nested DTO for the `user_stats` sub-join inside `KudosProfileDTO`.
///
/// PostgREST returns an embedded resource as a JSON **object** (not a scalar),
/// so `kudos_received_count:user_stats(kudos_received_count)` produces
/// `{ "user_stats": { "kudos_received_count": 25 } }` — not the scalar `25`.
/// Decoding directly as `Int?` causes a `DecodingError.typeMismatch` at runtime.
struct KudosProfileUserStatsDTO: Codable, Sendable {

    let kudos_received_count: Int?

    enum CodingKeys: String, CodingKey {
        case kudos_received_count
    }
}

// MARK: - KudosProfileDTO

/// Nested join shape for a profile row embedded inside a kudos query.
///
/// Columns sourced from `public.profiles` (migration 20260610145900) plus
/// the `department_id` FK added by migration 20260619104601.
/// The `user_stats` sub-join carries `kudos_received_count` so `KudosMapper`
/// can derive `StarTier` without a second fetch.
/// Use `kudosReceivedCount` computed property rather than accessing `user_stats` directly.
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

// MARK: - KudosHashtagJoinDTO

/// Join shape for `kudos_hashtags(hashtag:hashtags(*))` nested select.
struct KudosHashtagJoinDTO: Codable, Sendable {

    let hashtag: HashtagDTO

    enum CodingKeys: String, CodingKey {
        case hashtag
    }
}

// MARK: - KudosReactionCountDTO

/// Aggregate shape returned when selecting `kudos_reactions(count)`.
///
/// Supabase PostgREST returns `[{"count": N}]` for an aggregate nested select;
/// we decode the first element's count as the `heartCount`.
struct KudosReactionCountDTO: Codable, Sendable {

    let count: Int

    enum CodingKeys: String, CodingKey {
        case count
    }
}

// MARK: - KudosDTO

/// Wire-format mirror of the `public.kudos` Postgres row plus its standard joins.
///
/// Column names match the migration `20260619104603_create_kudos_table.sql`.
/// Joined relations follow the Supabase nested-select naming convention:
///   - `sender`    → `profiles!sender_id(*)`
///   - `recipient` → `profiles!recipient_id(*)`
///   - `kudos_hashtags` → `kudos_hashtags(hashtag:hashtags(*))`
///   - `reactions` → `kudos_reactions(count)` for heart_count aggregate
///
/// `liked_by_me` is resolved client-side in the repository after fetching all
/// reaction `user_id`s for the batch, then threaded into the mapper.
/// See `SupabaseKudosRepository` for the fallback strategy when the nested
/// aggregate proves unreliable.
struct KudosDTO: Codable, Sendable {

    let id: UUID
    let sender_id: UUID
    let recipient_id: UUID
    let title: String?
    let message: String
    let award_category_name: String?
    let is_anonymous: Bool
    let anonymous_nickname: String?
    let photo_url: String?
    let status: String
    let created_at: Date
    let deleted_at: Date?

    // Joined relations (may be nil if select alias doesn't match or join is absent)
    let sender: KudosProfileDTO?
    let recipient: KudosProfileDTO?
    let kudos_hashtags: [KudosHashtagJoinDTO]?

    // heart_count: nested aggregate `kudos_reactions(count)`.
    // Supabase returns this as an array with one element; we take `.first?.count`.
    // If nil (e.g. aggregate quirk), the repository falls back to a separate count query.
    let reactions: [KudosReactionCountDTO]?

    enum CodingKeys: String, CodingKey {
        case id
        case sender_id
        case recipient_id
        case title
        case message
        case award_category_name
        case is_anonymous
        case anonymous_nickname
        case photo_url
        case status
        case created_at
        case deleted_at
        case sender
        case recipient
        case kudos_hashtags
        case reactions
    }

    /// Convenience accessor: total heart count from the nested aggregate.
    /// Returns 0 when the aggregate array is absent — the repository should
    /// treat 0 as a signal to apply the client-side fallback.
    var heartCount: Int { reactions?.first?.count ?? 0 }
}
