import SwiftUI

// MARK: - KVKudosBanner

/// Compact KV Kudos banner (MoMorph `mms_A_KV Kudos` — id `6885:10266`).
///
/// Renders the recognition-system tagline ("Hệ thống ghi nhận và cảm ơn")
/// and the KUDOS logo row (heart emblem + "KUDOS" word-mark).
/// Used as a shared chrome element on both the Kudos hero screen and the
/// Award detail screen. 221×67pt bounding box per Figma.
///
/// Figma values:
/// - Tagline (6885:10268): Montserrat Medium 14pt, #FFEA9E, lineHeight 20pt.
/// - Logo row (6885:10270): 221×39pt — reuses `kudos-hero-title` asset.
struct KVKudosBanner: View {

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            tagline
            logoRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }

    // MARK: - Tagline

    private var tagline: some View {
        Text(LocalizedStringKey("home.kudos.eyebrow"))
            .font(.custom("Montserrat-Medium", size: 14))
            .foregroundColor(.kvGold)
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("kvkudos.banner.tagline")
    }

    // MARK: - Logo row

    private var logoRow: some View {
        Image("kudos-hero-title")
            .resizable()
            .scaledToFit()
            .frame(width: 221, height: 39)
            .accessibilityLabel("Sun Kudos")
            .accessibilityIdentifier("kvkudos.banner.logo")
    }
}

// MARK: - Color tokens

private extension Color {
    /// Figma `Details-Text-Primary-1` — #FFEA9E.
    static let kvGold = Color(red: 1.0, green: 234.0 / 255, blue: 158.0 / 255)
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        KVKudosBanner()
            .padding(.vertical, 16)
    }
    .preferredColorScheme(.dark)
}
#endif
