import Foundation

// MARK: - UserStatsDTO

/// Wire-format mirror of the `public.user_stats` Postgres row.
///
/// Decoded by the Supabase SDK; never escapes the Data layer.
/// Column names match the migration `20260619104606_create_user_stats_table.sql`.
struct UserStatsDTO: Codable, Sendable {

    let user_id: UUID
    let kudos_received_count: Int
    let kudos_sent_count: Int
    let kudos_hearts_received: Int
    let secret_boxes_opened: Int
    let secret_boxes_unopened: Int
    let updated_at: Date

    enum CodingKeys: String, CodingKey {
        case user_id
        case kudos_received_count
        case kudos_sent_count
        case kudos_hearts_received
        case secret_boxes_opened
        case secret_boxes_unopened
        case updated_at
    }
}
