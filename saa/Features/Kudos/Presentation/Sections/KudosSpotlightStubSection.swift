import SwiftUI

/// Spotlight Board static stub (MoMorph `B.6. Spotlight board` — id `6885:9099`).
///
/// Per clarification 2026-06-18: the live network chart + search is deferred to a
/// follow-up plan. This view renders a static placeholder so the section chrome is
/// visible without any business logic.
///
/// Structure:
///   - Section header via `KudosSectionHeader(subtitle:title:)` — matches Figma
///     `header` node (6885:9100): eyebrow "Sun* Annual Awards 2025", title "SPOTLIGHT BOARD"
///   - Placeholder card with text "Tính năng đang được phát triển"
///
/// No callbacks — this section has no interactive elements in the stub phase.
@MainActor
struct KudosSpotlightStubSection: View {

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header — KudosSectionHeader is provided by a sibling subagent.
            // Init: KudosSectionHeader(subtitle:title:)
            KudosSectionHeader(
                subtitle: String(localized: "kudos.section.subtitle"),
                title: String(localized: "kudos.section.spotlight")
            )

            placeholderCard
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Placeholder card

    /// Dark rounded card mirroring the container shape the live chart will occupy.
    /// Text "Tính năng đang được phát triển" (feature in development) per clarification.
    private var placeholderCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.spotlightPlaceholderIcon)

            Text(LocalizedStringKey("kudos.spotlight.comingSoon"))
                .font(.custom("Montserrat-Regular", size: 14))
                .foregroundColor(.spotlightPlaceholderText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(Color.spotlightCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.spotlightCardBorder, lineWidth: 0.794)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Spotlight Board — \(String(localized: "kudos.spotlight.comingSoon"))")
        .accessibilityIdentifier("kudos.spotlightStub.placeholder")
    }
}

// MARK: - Color tokens

private extension Color {
    /// Figma `Details-Container-2` — #00070C.
    static let spotlightCardBackground  = Color(red: 0, green: 7.0/255, blue: 12.0/255)
    /// Figma `Details-Border` — #998C5F.
    static let spotlightCardBorder      = Color(red: 153.0/255, green: 140.0/255, blue: 95.0/255)
    /// Muted white for placeholder copy.
    static let spotlightPlaceholderText = Color.white.opacity(0.5)
    /// Muted gold tint for placeholder icon.
    static let spotlightPlaceholderIcon = Color(red: 1.0, green: 234.0/255, blue: 158.0/255).opacity(0.4)
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        KudosSpotlightStubSection()
            .padding(.vertical, 20)
    }
    .preferredColorScheme(.dark)
}
#endif
