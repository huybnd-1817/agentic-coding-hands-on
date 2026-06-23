import Foundation

// MARK: - HashtagDTO

/// Wire-format mirror of the `public.hashtags` Postgres row.
///
/// Decoded by the Supabase SDK; never escapes the Data layer.
/// Column names match the migration `20260619104602_create_hashtags_table.sql`.
struct HashtagDTO: Codable, Sendable {

    let id: UUID
    let tag: String

    enum CodingKeys: String, CodingKey {
        case id
        case tag
    }
}
