import Foundation

// MARK: - Award

/// Domain entity representing a single SAA 2025 award category.
///
/// Pure Swift — imports `Foundation` only. Localised strings are carried
/// side-by-side; the Presentation layer picks `nameEN` vs `nameVI` from the
/// current `\.locale`. No SDK or persistence type leaks into this entity.
struct Award: Sendable, Equatable, Identifiable {

    let id: UUID
    /// Stable natural key (e.g. `"top_talent"`). Used for analytics +
    /// asset lookup. Unique across the awards table.
    let code: String
    let nameEN: String
    let nameVI: String
    let descriptionEN: String
    let descriptionVI: String
    /// Remote thumbnail. `nil` triggers the placeholder fallback at the view
    /// layer (covers TC_FUN_010).
    let thumbnailURL: URL?
    /// Ascending sort key — surfaced as the natural display order.
    let sortOrder: Int

    // MARK: Detail-screen fields (Phase 07)

    /// Number of award slots (e.g. 10 for Top Talent, 1 for MVP).
    let quantity: Int
    /// Recipient type label stored in Vietnamese (e.g. "Cá nhân", "Tập thể").
    let quantityUnit: String
    /// Formatted prize value for an individual recipient (e.g. "7.000.000 VNĐ").
    let prizeValueIndividual: String
    /// Formatted prize value for a team recipient. Non-nil only for the
    /// Signature 2025 - Creator variant which awards both individual and team.
    let prizeValueTeam: String?
    /// Contextual note displayed beneath the prize value
    /// (e.g. "cho mỗi giải thưởng").
    let prizeNote: String
}
