import Foundation

// MARK: - CreateKudoDTO

/// Wire-format body for `POST /kudos`.
///
/// `sender_id` is included and must equal `auth.uid()` — the RLS INSERT policy
/// enforces `auth.uid() = sender_id`, so any attempt to forge a different sender
/// is rejected by the server (clarifications.md §rls-path).
///
/// `CodingKeys` use snake_case to match Postgres column names without needing
/// any `JSONEncoder.keyEncodingStrategy` configuration on the Supabase client.
struct CreateKudoDTO: Encodable, Sendable {

    let sender_id: String
    let recipient_id: String
    let title: String
    let message: String
    let is_anonymous: Bool
    let anonymous_nickname: String?

    enum CodingKeys: String, CodingKey {
        case sender_id
        case recipient_id
        case title
        case message
        case is_anonymous
        case anonymous_nickname
    }
}

// MARK: - KudosInsertResponseDTO

/// Minimal shape returned by the `INSERT … RETURNING id` call.
///
/// We only need the generated `id` to proceed with the hashtag and attachment
/// batch inserts. The full kudos is re-fetched via a separate SELECT with joins.
struct KudosInsertResponseDTO: Decodable, Sendable {

    let id: UUID

    enum CodingKeys: String, CodingKey {
        case id
    }
}
