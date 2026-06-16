import SwiftUI

/// Hero section (MoMorph node `mms_2_content` — id `6885:8983`):
///   - ROOT FURTHER artwork (247×109 from design)
///   - "Coming soon" eyebrow + segmented two-digit countdown (DAYS / HOURS / MINUTES)
///   - Event-info rows: Thời gian + Địa điểm + livestream note
///   - ABOUT AWARD (gold filled) + ABOUT KUDOS (gold outlined) action buttons
///
/// Layout uses the Figma frame gaps (32px outer, 24px between countdown/info,
/// 8px inside each sub-frame, 16px between countdown units).
struct HomeHeroSection: View {

    // MARK: - Inputs

    let countdown: Countdown
    let eventDateText: String
    let venueName: String

    // MARK: - Outputs

    let onAboutAward: () -> Void
    let onAboutKudos: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Image("root-further")
                .resizable()
                .scaledToFit()
                .frame(width: 247, height: 109)

            // Countdown + event info — Figma "Frame 553" (gap=24, gap=8 inside)
            VStack(alignment: .leading, spacing: 24) {
                countdownBlock
                eventInfoBlock
            }

            // ABOUT AWARD / ABOUT KUDOS — Figma "actions" frame (gap=16)
            HStack(spacing: 16) {
                aboutAwardButton
                aboutKudosButton
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }

    // MARK: - Countdown block

    private var countdownBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey("home.hero.comingSoon"))
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.white)

            HStack(spacing: 16) {
                countdownUnit(value: countdown.days,    labelKey: "home.hero.days")
                countdownUnit(value: countdown.hours,   labelKey: "home.hero.hours")
                countdownUnit(value: countdown.minutes, labelKey: "home.hero.minutes")
            }
        }
    }

    /// One countdown unit — two digit boxes + label below.
    /// Two-digit display clamped to 99 to match the Figma frame width.
    private func countdownUnit(value: Int, labelKey: LocalizedStringKey) -> some View {
        let clamped = max(0, min(value, 99))
        let tens = clamped / 10
        let ones = clamped % 10
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                digitBox(digit: tens)
                digitBox(digit: ones)
            }

            Text(labelKey)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.white)
                .tracking(0.5)
        }
    }

    /// Single digit box — 32×56, rounded corners, gold border, translucent white
    /// gradient fill at 50% opacity. Matches Figma `number/Rectangle 1`.
    private func digitBox(digit: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(0.5)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.countdownBorder, lineWidth: 0.5)
                )

            Text("\(digit)")
                .font(.system(size: 32, weight: .regular, design: .monospaced))
                .foregroundColor(.white)
        }
        .frame(width: 32, height: 56)
    }

    // MARK: - Event info block

    private var eventInfoBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            eventInfoRow(
                labelKey: "home.hero.dateLabel",
                value: eventDateText
            )

            eventInfoRow(
                labelKey: "home.hero.venueLabel",
                value: venueName
            )

            Text(LocalizedStringKey("home.hero.livestreamNote"))
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func eventInfoRow(labelKey: LocalizedStringKey, value: String) -> some View {
        HStack(spacing: 8) {
            Text(labelKey)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.white)

            Text(value)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.heroAccentGold)
        }
    }

    // MARK: - Action buttons

    private var aboutAwardButton: some View {
        Button(action: onAboutAward) {
            HStack(spacing: 8) {
                Text(LocalizedStringKey("home.hero.aboutAward"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.heroDarkText)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.heroDarkText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(Color.heroAccentGold)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .accessibilityIdentifier("home.hero.aboutAward")
    }

    private var aboutKudosButton: some View {
        Button(action: onAboutKudos) {
            HStack(spacing: 8) {
                Text(LocalizedStringKey("home.hero.aboutKudos"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(Color.heroAccentGold.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.countdownBorder, lineWidth: 1)
            )
        }
        .accessibilityIdentifier("home.hero.aboutKudos")
    }
}

// MARK: - Color tokens

private extension Color {
    /// Figma `Details-Text-Primary-1` — #FFEA9E. Used for gold borders + values.
    static let heroAccentGold   = Color(red: 1.0, green: 234.0/255, blue: 158.0/255)
    /// Figma `Colors-Boder` — #998C5F. Outlined-button border.
    static let countdownBorder  = Color(red: 153.0/255, green: 140.0/255, blue: 95.0/255)
    /// Figma button-on-gold text color — #00101A.
    static let heroDarkText     = Color(red: 0.0,  green: 16.0/255,  blue: 26.0/255)
}

// MARK: - Preview

#if DEBUG
#Preview {
    ScrollView {
        ZStack {
            Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
            HomeHeroSection(
                countdown: HomeMockData.previewCountdown,
                eventDateText: "26/12/2026",
                venueName: "Âu Cơ Art Center",
                onAboutAward: {},
                onAboutKudos: {}
            )
            .padding(.vertical, 20)
        }
    }
    .preferredColorScheme(.dark)
}
#endif
