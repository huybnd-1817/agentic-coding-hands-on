import Foundation

// MARK: - StarTier

/// Discrete prestige tier derived from how many kudos a user has received.
///
/// Computed purely from `KudosAuthor.kudosReceivedCount` in the domain — there
/// is no `star_tier` column in the database (clarifications.md, 2026-06-18).
/// Views call `StarTier.from(received:)` when rendering the star badge on
/// sender/recipient cards.
///
/// Thresholds (floor-based, per clarifications.md):
///   - 0 – 9   → `.zero`  (0 stars)
///   - 10 – 19 → `.one`   (1 star)
///   - 20 – 49 → `.two`   (2 stars)
///   - ≥ 50    → `.three` (3 stars)
enum StarTier: Int, Sendable, CaseIterable {
    case zero  = 0
    case one   = 1
    case two   = 2
    case three = 3

    // MARK: - Derivation

    /// Derives the tier from a raw received-kudos count using floor thresholds.
    ///
    /// - Parameter received: The `kudosReceivedCount` from `KudosAuthor`.
    /// - Returns: The corresponding `StarTier`.
    static func from(received: Int) -> StarTier {
        switch received {
        case ..<10:  return .zero
        case 10..<20: return .one
        case 20..<50: return .two
        default:     return .three
        }
    }
}
