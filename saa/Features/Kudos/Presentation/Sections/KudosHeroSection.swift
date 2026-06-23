import SwiftUI

/// Kudos screen Hero text block (MoMorph `mms_A_KV Kudos` — id `6885:9066`).
///
/// Renders only the tagline ("Hệ thống ghi nhận và cảm ơn") and the KUDOS
/// title row (small heart emblem + bold gold "KUDOS" text). The full-bleed
/// key-visual background lives one level up in `KudosView`, so this section
/// is pure text content overlaid on that screen-wide artwork.
///
/// Figma values:
/// - Tagline (6885:9068): Montserrat Medium 14pt, color #FFEA9E, lineHeight 20pt.
/// - Emblem (6885:9071): 49×38pt, asset `kudos-logo-title.svg`.
/// - "KUDOS" text (6885:9077): 163×39pt, rendered here as Montserrat Black 36pt
///   in #FFEA9E gold matching the Figma vector word-mark.
struct KudosHeroSection: View {

    // MARK: - Body

    var body: some View {
        // Figma mms_A_KV Kudos: VStack gap=8pt, width=221pt, height=67pt,
        // anchored at (20, 144) on the canvas.
        VStack(alignment: .leading, spacing: 8) {
            tagline
            logoRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Tagline

    private var tagline: some View {
        Text(LocalizedStringKey("kudos.hero.tagline"))
            .font(.custom("Montserrat-Medium", size: 14))
            .foregroundColor(.kudosGold)
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("kudos.hero.tagline")
    }

    // MARK: - Logo row (heart emblem + KUDOS word-mark, one image)
    //
    // Figma `kudo logo` (6885:9070) is a 221×39pt frame. The KUDOS word-mark
    // (6885:9077) is a vector group that isn't exportable as a standalone
    // asset via MCP, so we render the entire row by cropping the rendered
    // frame at exact figma coordinates → bundled as `kudos-hero-title` (3x PNG).
    // This guarantees pixel-perfect parity with the design's letterforms.

    private var logoRow: some View {
        Image("kudos-hero-title")
            .resizable()
            .scaledToFit()
            .frame(width: 221, height: 39)
            .accessibilityLabel("Sun Kudos")
            .accessibilityIdentifier("kudos.hero.title")
    }
}

// MARK: - Color tokens

private extension Color {
    /// Figma `Details-Text-Primary-1` — #FFEA9E.
    static let kudosGold = Color(red: 1.0, green: 234.0 / 255, blue: 158.0 / 255)
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        KudosHeroSection()
    }
    .preferredColorScheme(.dark)
}
#endif
