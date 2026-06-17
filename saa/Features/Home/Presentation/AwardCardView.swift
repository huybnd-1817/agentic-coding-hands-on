import SwiftUI

/// Single award card in the horizontally-paged Awards carousel.
///
/// Matches Figma `mms_4.2_award list / Top Talent Award` (component `6885:8051`):
///   • Card: 160 × 298, gap 12 between picture / text / button.
///   • Picture: 160 × 160 dark square, 0.455 gold border, 11.429 corner
///     radius, gold-glow + dark drop shadow, centered trophy + uppercase
///     gold name (per-award PNG logos are NOT used — single consistent
///     treatment for all 6 cards, per session clarification 2026-06-17).
///   • Name (below picture): 14pt Montserrat-equivalent .medium, gold.
///   • Description: 14pt .light, white, line-height 20pt, capped at 3 lines.
///   • Per-card "Chi tiết" button (no fill, white label + gold arrow) is the
///     ONLY tap target — the picture and text are decorative.
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
            RoundedRectangle(cornerRadius: 11.429)
                .fill(Color.awardPictureBg)

            VStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundColor(Color.awardGold)

                Text(award.title(for: locale))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.awardGold)
                    .textCase(.uppercase)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
            }
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
                    .foregroundColor(Color.awardGold)
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
    static let awardGold       = Color(red: 1.0,        green: 234.0/255, blue: 158.0/255)
    /// Figma box-shadow gold halo — #FAE287.
    static let awardGlow       = Color(red: 250.0/255,  green: 226.0/255, blue: 135.0/255)
    /// Inner picture fill — dark base behind the gold name.
    static let awardPictureBg  = Color(red: 0.06,       green: 0.10,      blue: 0.13)
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
