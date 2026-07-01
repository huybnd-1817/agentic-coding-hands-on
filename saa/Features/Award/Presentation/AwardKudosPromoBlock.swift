import SwiftUI

// MARK: - AwardKudosPromoBlock

/// Sun* Kudos recognition promo block shown at the bottom of every award variant.
///
/// Matches Figma `mms_2.4_kudos` (id `6885:10315`):
/// - Header: eyebrow "Phong trào ghi nhận" + divider + gold title "Sun* Kudos" (22pt Medium).
/// - Banner card: 335×145pt, `MM_MEDIA_Kudos Background` + Kudos logo overlay.
/// - Body text: badge line + description paragraph (Montserrat Light 14pt white).
/// - CTA button: 160×40pt, #FFEA9E fill, #00101A text, rounded-rect 4pt.
struct AwardKudosPromoBlock: View {

    // MARK: - Outputs

    let onTapKudosCTA: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HomeSectionHeader(
                eyebrowKey: "award.detail.kudos.label",
                titleKey: "home.kudos.sectionTitle"
            )

            bannerCard
                .padding(.horizontal, 20)

            bodyText
                .padding(.horizontal, 20)

            ctaButton
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Banner card (335×145)

    private var bannerCard: some View {
        ZStack(alignment: .trailing) {
            Image("home-kudos-banner")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 145)
                .clipShape(RoundedRectangle(cornerRadius: 4.65))

            Image("home-kudos-logo")
                .resizable()
                .scaledToFit()
                .frame(width: 118, height: 21)
                .padding(.trailing, 22)
        }
        .frame(height: 145)
        .accessibilityIdentifier("award.kudos.banner")
    }

    // MARK: - Body text (badge + description)

    private var bodyText: some View {
        Text(LocalizedStringKey("award.detail.kudos.description"))
            .font(.system(size: 14, weight: .light))
            .foregroundColor(.white)
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - CTA button

    private var ctaButton: some View {
        Button(action: onTapKudosCTA) {
            HStack(spacing: 8) {
                Text(LocalizedStringKey("award.detail.kudos.cta"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.kudosPromoButtonText)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.kudosPromoButtonText)
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
            .frame(minWidth: 120)
            .background(Color.kudosPromoButtonFill)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .accessibilityIdentifier("award.kudos.cta")
    }
}

// MARK: - Color tokens

private extension Color {
    /// Figma CTA button fill — #FFEA9E.
    static let kudosPromoButtonFill = Color(red: 1.0, green: 234.0/255, blue: 158.0/255)
    /// Figma CTA on-gold text — #00101A.
    static let kudosPromoButtonText = Color(red: 0.0, green: 16.0/255, blue: 26.0/255)
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        ScrollView {
            AwardKudosPromoBlock(onTapKudosCTA: {})
                .padding(.vertical, 20)
        }
    }
    .preferredColorScheme(.dark)
}
#endif
