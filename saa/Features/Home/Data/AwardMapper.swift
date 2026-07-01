import Foundation

// MARK: - AwardDTO

/// Wire-format mirror of the `public.awards` Postgres row.
///
/// Decoded by the Supabase SDK; never escapes the Data layer. The `snake_case`
/// keys match the column names declared in
/// `supabase/migrations/20260615161000_create_awards_table.sql`.
struct AwardDTO: Decodable, Sendable {

    let id: UUID
    let code: String
    let name_en: String
    let name_vi: String
    let description_en: String
    let description_vi: String
    let thumbnail_url: String?
    let sort_order: Int

    // Detail-screen columns (Phase 08). Declared optional so the decoder
    // survives schema drift — if the migration hasn't been applied to the
    // remote yet, the row decodes with `nil` instead of crashing. The mapper
    // substitutes safe defaults below.
    let quantity: Int?
    let quantity_unit: String?
    let prize_value_individual: String?
    let prize_value_team: String?
    let prize_note: String?
}

// MARK: - AwardMapper

/// Lifts a `AwardDTO` (Data) into an `Award` (Domain), stripping the SDK shape.
enum AwardMapper {

    static func toDomain(_ dto: AwardDTO) -> Award {
        Award(
            id: dto.id,
            code: dto.code,
            nameEN: dto.name_en,
            nameVI: dto.name_vi,
            descriptionEN: dto.description_en,
            descriptionVI: dto.description_vi,
            thumbnailURL: dto.thumbnail_url.flatMap(URL.init(string:)),
            sortOrder: dto.sort_order,
            quantity: dto.quantity ?? 0,
            quantityUnit: dto.quantity_unit ?? "",
            prizeValueIndividual: dto.prize_value_individual ?? "",
            prizeValueTeam: dto.prize_value_team,
            prizeNote: dto.prize_note ?? ""
        )
    }
}
