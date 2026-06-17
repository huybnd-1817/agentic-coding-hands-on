import SwiftUI

/// Single award card in the horizontally-paged Awards carousel.
///
/// Matches Figma `mms_4.2_award list / Top Talent Award` (component `6885:8051`):
///   • Card: 160 × 298, gap 12 between picture / text / button.
///   • Picture: 160 × 160 with the Figma `MM_MEDIA_Award BG` image, 0.455
///     gold border, 11.429 corner radius, gold-glow + dark drop shadow.
///     Top Talent + Top Project overlay the Figma name logo PNGs; the other
///     four awards (no prepared logo in Figma) show the uppercase gold name
///     as a styled text overlay.
///   • Name (below picture): 14pt Montserrat-equivalent .medium, gold.
///   • Description: 14pt .light, white, line-height 20pt, capped at 3 lines.
///   • Per-card "Chi tiết" button (no fill, white label + white arrow) is
///     the ONLY tap target — the picture and text are decorative.
struct AwardCardView: View {

    // MARK: - Inputs

    let award: Award

    // MARK: - Outputs

    let onDetailTap: () -> Void

    // MARK: - Environment

    @SwiftUI.Environment(\.locale) private var locale

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            pictureBlock

            nameAndDescription

            detailButton
        }
        .frame(width: 160, alignment: .topLeading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.awards.card.\(award.code)")
    }

    // MARK: - Picture (160 × 160 square)

    private var pictureBlock: some View {
        ZStack {
            // Figma `MM_MEDIA_Award BG` — dark trophy backdrop shared by all
            // cards. Clipped to the 11.429-corner shape with a gold border.
            Image("award-picture-bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 160, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 11.429))

            // Per-award name overlay — Figma logo PNG when prepared, else a
            // styled text fallback so all 6 codes get a legible nameplate.
            namePlate
                .padding(.horizontal, 16)
        }
        .frame(width: 160, height: 160)
        .overlay(
            RoundedRectangle(cornerRadius: 11.429)
                .stroke(Color.awardGold, lineWidth: 0.455)
        )
        // Gold glow + drop shadow per Figma box-shadow:
        // `0 0 2.857 #FAE287, 0 1.905 1.905 rgba(0,0,0,0.25)`.
        .shadow(color: Color.awardGlow.opacity(0.55), radius: 3, x: 0, y: 0)
        .shadow(color: Color.black.opacity(0.25), radius: 1.9, x: 0, y: 1.9)
    }

    /// Award name rendered as gold styled text or, when Figma provides a
    /// prepared name-logo PNG, as the source asset itself.
    @ViewBuilder
    private var namePlate: some View {
        if let logoAsset = Self.logoAsset(for: award.code) {
            Image(logoAsset)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 128, maxHeight: 24)
        } else {
            Text(award.title(for: locale))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.awardGold)
                .textCase(.uppercase)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Maps an award `code` to a prepared Figma logo asset.
    /// Returns `nil` when no logo PNG exists in the catalogue.
    private static func logoAsset(for code: String) -> String? {
        switch code {
        case "top_talent":  return "award-logo-top-talent"
        case "top_project": return "award-logo-top-project"
        default:            return nil
        }
    }

    // MARK: - Name + description (Figma `Frame 490`, 160 × 82)

    private var nameAndDescription: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(award.title(for: locale))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.awardGold)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(award.subtitle(for: locale))
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.white)
                .lineSpacing(6)
                .lineLimit(3)
                .truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(width: 160, height: 82, alignment: .topLeading)
    }

    // MARK: - Per-card "Chi tiết" button (Figma button, 84 × 32, no fill)

    private var detailButton: some View {
        Button(action: onDetailTap) {
            HStack(spacing: 8) {
                Text(LocalizedStringKey("home.awards.details"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 84, height: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.awards.card.\(award.code).details")
    }
}

// MARK: - Color tokens

private extension Color {
    /// Figma `--Details-Text-Primary-1` — #FFEA9E.
    static let awardGold = Color(red: 1.0,       green: 234.0/255, blue: 158.0/255)
    /// Figma box-shadow gold halo — #FAE287.
    static let awardGlow = Color(red: 250.0/255, green: 226.0/255, blue: 135.0/255)
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        HStack(spacing: 12) {
            AwardCardView(award: HomeMockData.previewAwards[0], onDetailTap: {})
            AwardCardView(award: HomeMockData.previewAwards[1], onDetailTap: {})
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
#endif
