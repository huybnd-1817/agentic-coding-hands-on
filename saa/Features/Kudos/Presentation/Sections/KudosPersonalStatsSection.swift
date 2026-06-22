import SwiftUI

/// Personal Statistics card (MoMorph `mms_D.1_Thống kê tổng quát` — id `6885:9223`).
///
/// Renders a dark-background rounded card with five stat rows AND the
/// "Open Secret Box" CTA button as the final row inside the card:
///   - Kudos received (D.1.2)
///   - Kudos sent (D.1.3)
///   - Hearts received (D.1.4) with optional x2 fire badge
///   - [divider — D.1.5]
///   - Secret Boxes opened (D.1.6)
///   - Secret Boxes unopened (D.1.7)
///   - Open Secret Box button (id `6885:9254`)
///
/// Per Figma the Secret Box button lives *inside* the `mms_D.1` card — not
/// as a sibling between stats and the Top-10 recipients list. Owning the
/// button here keeps the card and its action visually grouped as designed.
///
/// Design values (Figma node 6885:9223):
/// - Background: #00070C, border: 0.794pt solid #998C5F, corner radius: 8pt, padding: 12pt
/// - Row height: ~20pt, gap between rows: 12pt
/// - Label: Montserrat Light 14pt, white (#FFFFFF)
/// - Count: Montserrat Bold 14pt, gold (#FFEA9E)
/// - Divider: 1pt #2E3940
@MainActor
struct KudosPersonalStatsSection: View {

    // MARK: - Inputs

    let stats: KudosPersonalStatsData
    /// When `true`, the Hearts row shows a flame-x2 badge (active event bonus).
    let showFireBadge: Bool
    /// Forwarded to the embedded `KudosSecretBoxButton`. Tapping fires
    /// `onOpenSecretBox` only when the button is enabled.
    let onOpenSecretBox: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            statRow(labelKey: "kudos.stats.received", count: stats.kudosReceived)
            statRow(labelKey: "kudos.stats.sent", count: stats.kudosSent)
            heartsRow
            divider
            statRow(labelKey: "kudos.stats.boxesOpened", count: stats.secretBoxesOpened)
            statRow(labelKey: "kudos.stats.boxesUnopened", count: stats.secretBoxesUnopened)

            KudosSecretBoxButton(
                isEnabled: stats.secretBoxesUnopened > 0,
                onTap: onOpenSecretBox
            )
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.statsCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.statsCardBorder, lineWidth: 0.794)
        )
    }

    // MARK: - Standard stat row

    /// `labelKey` is typed as `LocalizedStringKey` (not pre-resolved `String`)
    /// so the row's `Text` tracks the SwiftUI `\.locale` environment. With a
    /// raw `String` the row would freeze at the locale value present when its
    /// parent's body was last evaluated, which is why switching language did
    /// not update these labels at runtime.
    private func statRow(labelKey: LocalizedStringKey, count: Int) -> some View {
        HStack(alignment: .center) {
            Text(labelKey)
                .font(.custom("Montserrat-Light", size: 14))
                .foregroundColor(.statsLabel)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text("\(count)")
                .font(.custom("Montserrat-Bold", size: 14))
                .foregroundColor(.statsCount)
        }
        .frame(height: 20)
    }

    // MARK: - Hearts row (with optional x2 fire badge)

    private var heartsRow: some View {
        HStack(alignment: .center) {
            HStack(spacing: 30) {
                Text(LocalizedStringKey("kudos.stats.hearts"))
                    .font(.custom("Montserrat-Light", size: 14))
                    .foregroundColor(.statsLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                if showFireBadge {
                    fireBadge
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(stats.heartsReceived)")
                .font(.custom("Montserrat-Bold", size: 14))
                .foregroundColor(.statsCount)
        }
        .frame(minHeight: 20)
    }

    /// Flame badge — clean flame icon exported from Figma node `6885:9240`
    /// (`image 35` only, no "x2" text overlay). Shown next to the "Hearts
    /// received" label when an event bonus is active.
    /// Source size: 24×28.541pt → rendered at 24×28pt (rounded).
    /// The VM sets `showFireBadge = true` when `bonus.multiplier > 1`.
    private var fireBadge: some View {
        Image("kudos-stats-fire")
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 28)
            .accessibilityLabel("Nhân đôi tim")
    }

    // MARK: - Divider (D.1.5)

    private var divider: some View {
        Rectangle()
            .fill(Color.statsDivider)
            .frame(maxWidth: .infinity)
            .frame(height: 1)
    }
}

// MARK: - Color tokens

private extension Color {
    /// Figma `Details-Container-2` — #00070C.
    static let statsCardBackground = Color(red: 0, green: 7.0/255, blue: 12.0/255)
    /// Figma `Details-Border` — #998C5F.
    static let statsCardBorder     = Color(red: 153.0/255, green: 140.0/255, blue: 95.0/255)
    /// Figma stat label — rgba(255,255,255,1) / white.
    static let statsLabel          = Color.white
    /// Figma stat count — rgba(255,234,158,1) / gold.
    static let statsCount          = Color(red: 1.0, green: 234.0/255, blue: 158.0/255)
    /// Figma divider — rgba(46,57,64,1).
    static let statsDivider        = Color(red: 46.0/255, green: 57.0/255, blue: 64.0/255)
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        VStack(spacing: 16) {
            KudosPersonalStatsSection(
                stats: .mock,
                showFireBadge: true,
                onOpenSecretBox: {}
            )
            KudosPersonalStatsSection(
                stats: .mock,
                showFireBadge: false,
                onOpenSecretBox: {}
            )
        }
        .padding(.horizontal, 20)
    }
    .preferredColorScheme(.dark)
}
#endif
