import SwiftUI

/// Shown when the awards fetch fails. Displays the localized "could not load"
/// message and a Retry button that fires `onRetry` — wired to `onRetryAwards`
/// at the root. Message text comes from the `home.awards.error` xcstrings key
/// so the surface stays locale-aware (no parameter required).
struct AwardsErrorView: View {

    // MARK: - Outputs

    let onRetry: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(Color.errorIconColor)

            Text(LocalizedStringKey("home.awards.error"))
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Button(action: onRetry) {
                Text(LocalizedStringKey("home.awards.retry"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .background(Color.retryButtonBg)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .accessibilityIdentifier("home.awards.retry")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        // children: .contain keeps the inner Retry button reachable by XCUITest.
        // Without it, applying the identifier on the container collapses the
        // subtree into a single element and `home.awards.retry` disappears.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.awards.errorView")
    }
}

// MARK: - Color tokens

private extension Color {
    static let errorIconColor  = Color(red: 1.0, green: 0.72, blue: 0.0)
    static let retryButtonBg   = Color(red: 1.0, green: 234.0/255, blue: 158.0/255)
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        AwardsErrorView(onRetry: {})
    }
    .preferredColorScheme(.dark)
}
#endif
