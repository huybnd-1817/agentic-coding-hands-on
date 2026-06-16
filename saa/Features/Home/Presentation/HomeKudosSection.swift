import SwiftUI

/// Sun* Kudos promo block (MoMorph `mms_5_kudos` — id `6885:9039`).
/// Header (eyebrow + divider + gold title) → banner image with KUDOS logo →
/// long description paragraph → "Chi tiết" gold action button. Conditionally
/// rendered based on the `isKudosAvailable` feature flag.
struct HomeKudosSection: View {

    // MARK: - Outputs

    let onKudosDetail: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HomeSectionHeader(
                eyebrowKey: "home.kudos.eyebrow",
                titleKey: "home.kudos.sectionTitle"
            )

            bannerCard
                .padding(.horizontal, 20)

            description
                .padding(.horizontal, 20)

            detailButton
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Banner

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
        .accessibilityIdentifier("home.kudos.banner")
    }

    // MARK: - Description paragraph

    private var description: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LocalizedStringKey("home.kudos.bodyTitle"))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            Text(LocalizedStringKey("home.kudos.body"))
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.white)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Detail button

    private var detailButton: some View {
        Button(action: onKudosDetail) {
            HStack(spacing: 8) {
                Text(LocalizedStringKey("home.kudos.details"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.kudosButtonText)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.kudosButtonText)
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
            .frame(minWidth: 160)
            .background(Color.kudosButtonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .accessibilityIdentifier("home.kudos.details")
    }
}

// MARK: - Color tokens

private extension Color {
    /// Figma button fill — #FFEA9E.
    static let kudosButtonBackground = Color(red: 1.0, green: 234.0/255, blue: 158.0/255)
    /// Figma button-on-gold text — #00101A.
    static let kudosButtonText       = Color(red: 0.0, green: 16.0/255,  blue: 26.0/255)
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        HomeKudosSection(onKudosDetail: {})
            .padding(.vertical, 20)
    }
    .preferredColorScheme(.dark)
}
#endif
