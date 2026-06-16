import Foundation

// MARK: - NavTab

/// Bottom navigation tab identifiers shared between `HomeBottomNavBar` and
/// `MainTabView`. Production type — lives outside the `HomeMockData` file so
/// it survives any future cleanup of the preview-only fixtures there.
///
/// The `rawValue` doubles as the human-readable label fallback when the
/// localized `home.nav.*` keys are unavailable.
enum NavTab: String, CaseIterable, Identifiable {
    case home    = "SAA 2025"
    case awards  = "Awards"
    case kudos   = "Kudos"
    case profile = "Profile"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .home:    "house.fill"
        case .awards:  "trophy.fill"
        case .kudos:   "hands.clap.fill"
        case .profile: "person.fill"
        }
    }
}
