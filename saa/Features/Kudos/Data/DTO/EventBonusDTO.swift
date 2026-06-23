import Foundation

// MARK: - EventBonusDTO

/// Wire-format mirror of the `public.event_bonuses` Postgres row.
///
/// Decoded by the Supabase SDK; never escapes the Data layer.
/// Column names match the migration `20260619104607_create_event_bonuses_table.sql`.
struct EventBonusDTO: Codable, Sendable {

    let id: UUID
    let starts_at: Date
    let ends_at: Date
    let multiplier: Int
    let label: String?

    enum CodingKeys: String, CodingKey {
        case id
        case starts_at
        case ends_at
        case multiplier
        case label
    }
}
