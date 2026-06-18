import Foundation

// MARK: - Countdown

/// Days / hours / minutes remaining until a target date.
///
/// Pure value type with no dependency on a clock — call sites compute via
/// `Countdown.until(_:from:)` and pass in `Date.now` (or an injected clock
/// for tests). Clamps to zero when the target is in the past (clarification
/// 2026-06-15 Q3 — TC_FUN_001 / TC_FUN_002 verification).
struct Countdown: Equatable, Sendable {

    let days: Int
    let hours: Int
    let minutes: Int

    static let zero = Countdown(days: 0, hours: 0, minutes: 0)

    /// Computes the remaining countdown from `now` to `target`. Past-event
    /// dates clamp every component to zero.
    static func until(_ target: Date, from now: Date) -> Countdown {
        let interval = target.timeIntervalSince(now)
        guard interval > 0 else { return .zero }

        let totalSeconds = Int(interval)
        let days    = totalSeconds / 86_400
        let hours   = (totalSeconds % 86_400) / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        return Countdown(days: days, hours: hours, minutes: minutes)
    }
}
