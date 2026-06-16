import Foundation

// MARK: - FeatureFlags

/// Compile-time feature flags for the Home feature.
///
/// Per clarification 2026-06-15 Q4: flag values are constants for now.
/// Migrate to remote config (Supabase row, `app_config`) when business needs it.
enum FeatureFlags {

    /// Controls full visibility of the Kudos section on Home (TC_GUI_005,
    /// TC_FUN_009). When `false` the section is omitted entirely — no disabled
    /// placeholder is rendered.
    static let isKudosAvailable: Bool = true

    /// SAA 2025 event date. Hard-coded from MoMorph spec item 2 ("26/12/2025").
    /// Past today's date (2026-06-15) by design; countdown clamps to zero per
    /// clarification 2026-06-15 Q3.
    static let eventDate: Date = {
        var components = DateComponents()
        components.year = 2025
        components.month = 12
        components.day = 26
        components.hour = 0
        components.minute = 0
        components.timeZone = TimeZone(identifier: "Asia/Saigon")
        return Calendar(identifier: .gregorian).date(from: components) ?? Date()
    }()
}
