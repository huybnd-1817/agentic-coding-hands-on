import Foundation

// MARK: - EventBonus

/// A time-bounded heart-reaction multiplier for special event days.
///
/// Configured in Supabase's `event_bonuses` table via `starts_at`/`ends_at`
/// window and a `multiplier` integer (typically 2 for double-heart days).
/// `ToggleKudosReactionUseCase` reads `isActive(now:)` to decide whether to
/// pass `multiplier: 2` or `multiplier: 1` to the repository.
struct EventBonus: Sendable, Hashable {
    let id: UUID
    /// ISO-8601 start of the bonus window (inclusive).
    let startsAt: Date
    /// ISO-8601 end of the bonus window (inclusive).
    let endsAt: Date
    /// Heart-count multiplier applied during the active window (e.g. `2`).
    let multiplier: Int
    /// Short human-readable label displayed in the UI (e.g. `"Double Heart Day"`).
    let label: String

    // MARK: - Helper

    /// Returns true when `now` falls within the bonus window (both bounds inclusive).
    ///
    /// Passing an injected `now` instead of `Date()` keeps this method
    /// deterministically testable without mocking the system clock.
    func isActive(now: Date) -> Bool {
        now >= startsAt && now <= endsAt
    }
}
