import SwiftUI

/// Pagination indicator for the Highlight Kudos carousel.
///
/// Matches Figma component `6885:8507` (node `6885:9098`):
///   - Layout: HStack, horizontally centered, gap 32pt, height 24pt.
///   - Left chevron (IC, 24×24pt) — fires `onPrev`.
///   - Centre label: "currentIndex/totalCount" — 14pt Montserrat Bold, white.
///     Figma shows "2/5" as the active state example.
///   - Right chevron (IC, 24×24pt) — fires `onNext`.
///
/// Prev/next buttons use `kudos-carousel-arrow` asset. Because the asset is a
/// directional arrow image, the right chevron is flipped horizontally via
/// `.scaleEffect(x: -1)`. If the asset is absent the view falls back to
/// SF Symbol `chevron.left` / `chevron.right` for identical visual weight.
///
/// This view is read-only — it does not own carousel state. The parent section
/// drives `currentIndex` and `totalCount`, and reacts to the callbacks.
struct KudosCarouselDots: View {

    // MARK: - Inputs

    /// 1-based current page index (matches Figma "2/5" convention).
    let currentIndex: Int
    let totalCount: Int

    // MARK: - Outputs

    let onPrev: () -> Void
    let onNext: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 32) {
            prevButton
            pageLabel
            nextButton
        }
        .frame(maxWidth: .infinity)
        .frame(height: 24)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("kudos.carousel.pagination")
    }

    // MARK: - Prev button

    private var prevButton: some View {
        Button(action: onPrev) {
            // Asset points RIGHT by default (figma svg path), so PREV mirrors it.
            arrowImage(pointsRight: false)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .disabled(currentIndex <= 1)
        .opacity(currentIndex <= 1 ? 0.4 : 1.0)
        .accessibilityLabel("Previous")
        .accessibilityIdentifier("kudos.carousel.prev")
    }

    // MARK: - Next button

    private var nextButton: some View {
        Button(action: onNext) {
            // NEXT keeps the asset's native right-pointing direction.
            arrowImage(pointsRight: true)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .disabled(currentIndex >= totalCount)
        .opacity(currentIndex >= totalCount ? 0.4 : 1.0)
        .accessibilityLabel("Next")
        .accessibilityIdentifier("kudos.carousel.next")
    }

    // MARK: - Page label
    //
    // Current page rendered in gold (#FFEA9E); total stays white for contrast.

    private var pageLabel: some View {
        (
            Text("\(currentIndex)").foregroundColor(.kudosPaginationActive)
            + Text("/\(totalCount)").foregroundColor(.white)
        )
        .font(.custom("Montserrat-Bold", size: 14))
        .monospacedDigit()
        .accessibilityLabel("Page \(currentIndex) of \(totalCount)")
    }

    // MARK: - Arrow image helper

    @ViewBuilder
    private func arrowImage(pointsRight: Bool) -> some View {
        // `kudos-carousel-arrow` SVG path points right natively. Mirror on X
        // when a left-pointing arrow is needed.
        if UIImage(named: "kudos-carousel-arrow") != nil {
            Image("kudos-carousel-arrow")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundColor(.white)
                .scaleEffect(x: pointsRight ? 1 : -1, y: 1)
        } else {
            Image(systemName: pointsRight ? "chevron.right" : "chevron.left")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Color tokens

private extension Color {
    /// Active page digit — Figma `Details-Text-Primary-1` #FFEA9E.
    static let kudosPaginationActive = Color(red: 1.0, green: 234.0 / 255, blue: 158.0 / 255)
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        VStack(spacing: 24) {
            KudosCarouselDots(currentIndex: 2, totalCount: 5, onPrev: {}, onNext: {})
            KudosCarouselDots(currentIndex: 1, totalCount: 5, onPrev: {}, onNext: {})
            KudosCarouselDots(currentIndex: 5, totalCount: 5, onPrev: {}, onNext: {})
        }
        .padding(.horizontal, 20)
    }
    .preferredColorScheme(.dark)
}
#endif
