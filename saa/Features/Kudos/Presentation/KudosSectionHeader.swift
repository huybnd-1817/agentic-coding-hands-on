import SwiftUI

/// Reusable section header for the Sun*Kudos screen. Matches Figma component
/// `6885:8015` (used by Highlight, Spotlight, and All Kudos sections).
///
/// Renders three layers top-to-bottom (gap 4pt):
///   1. Eyebrow subtitle — 12pt Montserrat Regular, white.
///   2. 1px horizontal divider — #2E3940.
///   3. Gold bold title — 22pt Montserrat Medium, #FFEA9E.
///
/// Mirrors `HomeSectionHeader` pattern but accepts plain `String` values
/// (not `LocalizedStringKey`) so callers can pass design strings or
/// localisation keys without extra wrapping. Call sites in the Kudos
/// feature own their own localisation keys.
struct KudosSectionHeader: View {

    // MARK: - Inputs

    /// Eyebrow line above the divider (e.g. "Sun* Annual Awards 2025").
    let subtitle: String
    /// Bold gold section title below the divider (e.g. "HIGHLIGHT KUDOS").
    let title: String

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(subtitle)
                .font(.custom("Montserrat-Regular", size: 12))
                .foregroundColor(.white)
                .lineLimit(1)

            Rectangle()
                .fill(Color.kudosSectionDivider)
                .frame(maxWidth: .infinity)
                .frame(height: 1)

            Text(title)
                .font(.custom("Montserrat-Medium", size: 22))
                .foregroundColor(.kudosSectionTitle)
                .lineLimit(1)
        }
    }
}

// MARK: - Color tokens

private extension Color {
    /// Figma `Rectangle 26` divider — rgba(46,57,64,1).
    static let kudosSectionDivider = Color(red: 46.0/255, green: 57.0/255, blue: 64.0/255)
    /// Figma `Details-Text-Primary-1` — #FFEA9E.
    static let kudosSectionTitle   = Color(red: 1.0, green: 234.0/255, blue: 158.0/255)
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        VStack(spacing: 32) {
            KudosSectionHeader(
                subtitle: "Sun* Annual Awards 2025",
                title: "HIGHLIGHT KUDOS"
            )
            KudosSectionHeader(
                subtitle: "Sun* Annual Awards 2025",
                title: "SPOTLIGHT BOARD"
            )
            KudosSectionHeader(
                subtitle: "Sun* Annual Awards 2025",
                title: "ALL KUDOS"
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }
    .preferredColorScheme(.dark)
}
#endif
