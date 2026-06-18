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

    /// SAA 2025 event date. Updated 2026-06-16 to 26/12/2026 so the countdown
    /// remains positive while the original event date sits in the past.
    static let eventDate: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 12
        components.day = 26
        components.hour = 0
        components.minute = 0
        components.timeZone = TimeZone(identifier: "Asia/Saigon")
        return Calendar(identifier: .gregorian).date(from: components) ?? Date()
    }()

    /// Venue name shown in the Home hero event-info block. Hard-coded from the
    /// MoMorph design (node 6885:9022 — "Âu Cơ Art Center"). Centralised here
    /// so swapping to a remote-config later only changes this file.
    static let venueName: String = "Âu Cơ Art Center"
}
