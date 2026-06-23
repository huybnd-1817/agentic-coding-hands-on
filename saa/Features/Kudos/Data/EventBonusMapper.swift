import Foundation

// MARK: - EventBonusMapper

/// Lifts an `EventBonusDTO` (Data) into an `EventBonus` (Domain).
enum EventBonusMapper {

    static func from(_ dto: EventBonusDTO) -> EventBonus {
        EventBonus(
            id: dto.id,
            startsAt: dto.starts_at,
            endsAt: dto.ends_at,
            multiplier: dto.multiplier,
            // `label` is nullable in DB; fall back to empty string so Domain
            // never receives nil — views that need to hide the label check isEmpty.
            label: dto.label ?? ""
        )
    }
}
