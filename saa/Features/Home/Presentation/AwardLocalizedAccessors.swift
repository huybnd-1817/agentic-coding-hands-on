import Foundation

// MARK: - Award locale accessors

/// Presentation-only helpers for picking EN/VI fields off the domain `Award`
/// entity at render time. Lives in the Presentation layer (not Domain) because
/// the locale lookup is a UI concern — `Award` itself stays pure.
extension Award {

    /// Title displayed on award cards — `nameVI` for Vietnamese, else `nameEN`.
    func title(for locale: Locale) -> String {
        isVietnamese(locale) ? nameVI : nameEN
    }

    /// Subtitle / description — same locale rule as `title(for:)`.
    func subtitle(for locale: Locale) -> String {
        isVietnamese(locale) ? descriptionVI : descriptionEN
    }

    private func isVietnamese(_ locale: Locale) -> Bool {
        locale.language.languageCode?.identifier == "vi"
    }
}
