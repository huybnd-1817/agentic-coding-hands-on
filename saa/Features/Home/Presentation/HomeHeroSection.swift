import SwiftUI

/// Hero section: ROOT FURTHER artwork + countdown + theme description paragraph
/// + "About Award" and "About Kudos" links. Extracted from MoMorph design.
struct HomeHeroSection: View {

    // MARK: - Inputs

    let countdown: Countdown

    // MARK: - Outputs

    let onAboutAward: () -> Void
    let onAboutKudos: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ROOT FURTHER artwork
            Image("root-further")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)

            Spacer().frame(height: 24)

            // Countdown row
            countdownRow
                .padding(.horizontal, 20)

            Spacer().frame(height: 20)

            // "About this Award" link
            Button(action: onAboutAward) {
                Text(LocalizedStringKey("home.hero.aboutAward"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.homeAccentGold)
                    .underline()
            }
            .accessibilityIdentifier("home.hero.aboutAward")
            .padding(.horizontal, 20)

            Spacer().frame(height: 20)

            // Theme description — long localized paragraph (home.theme.body)
            Text(LocalizedStringKey("home.theme.body"))
                .font(.system(size: 13, weight: .light))
                .foregroundColor(Color.white.opacity(0.85))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 20)

            Spacer().frame(height: 16)

            // "About Kudos" link
            Button(action: onAboutKudos) {
                Text(LocalizedStringKey("home.hero.aboutKudos"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.homeAccentGold)
                    .underline()
            }
            .accessibilityIdentifier("home.hero.aboutKudos")
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Countdown

    private var countdownRow: some View {
        HStack(spacing: 0) {
            countdownUnit(value: countdown.days,    labelKey: "home.hero.days")
            divider
            countdownUnit(value: countdown.hours,   labelKey: "home.hero.hours")
            divider
            countdownUnit(value: countdown.minutes, labelKey: "home.hero.minutes")
        }
    }

    private func countdownUnit(value: Int, labelKey: LocalizedStringKey) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 32, weight: .bold, design: .default))
                .foregroundColor(.white)
                .monospacedDigit()

            Text(labelKey)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.6))
                .kerning(1.5)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.2))
            .frame(width: 1, height: 44)
    }
}

// MARK: - Color tokens

private extension Color {
    /// Figma brand-gold #998C5F used for links.
    static let homeAccentGold = Color(red: 153.0/255, green: 140.0/255, blue: 95.0/255)
}

// MARK: - Preview

#if DEBUG
#Preview {
    ScrollView {
        ZStack {
            Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
            HomeHeroSection(
                countdown: HomeMockData.previewCountdown,
                onAboutAward: {},
                onAboutKudos: {}
            )
            .padding(.vertical, 20)
        }
    }
    .preferredColorScheme(.dark)
}
#endif
