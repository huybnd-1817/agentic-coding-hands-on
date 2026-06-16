import SwiftUI

/// Floating action button (MoMorph `mms_6_float button` — id `6885:9058`).
///
/// Capsule pill, gold fill, with two tap zones — a pencil glyph (write a
/// kudo) and the Sun* Kudos logo (open the kudos feed), separated by a "/"
/// glyph. Matches the Figma layout: width 89, height 48, radius 100, padding 8,
/// inner gap 8.
///
/// Double-tap prevention (TC_FUN_013) is owned by `HomeViewContainer.push(_:)`,
/// which gates duplicate pushes via a synchronous `path.last` check on its
/// typed `[HomeRoute]` array. A view-local `@State` gate cannot survive a
/// synthetic XCUITest `doubleTap()` because SwiftUI commits state on the next
/// runloop iteration — both touch events queue against the same `isNavigating`
/// snapshot. Keep the gate at the container level where it is race-free.
struct HomeFloatingActionButton: View {

    // MARK: - Outputs

    let onFabPencilTap: () -> Void
    let onFabKudosTap: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            // Pencil hit zone
            Button(action: onFabPencilTap) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.fabIconColor)
                        .frame(width: 24, height: 24)

                    Text("/")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundColor(.fabIconColor)
                        .frame(width: 9, height: 32)
                }
            }
            .accessibilityIdentifier("home.fab.pencil")

            // Kudos hit zone — the Sun*Kudos red "K" mark (Figma
            // `MM_MEDIA_IC_Kudos Logo`, 24×24). SVG is the brand color, so
            // no `.foregroundColor` is applied here.
            Button(action: onFabKudosTap) {
                Image("home-fab-kudos-mark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .accessibilityIdentifier("home.fab.kudos")
        }
        .padding(8)
        .background(Color.fabGold)
        .clipShape(Capsule())
        .shadow(color: .fabGoldGlow.opacity(0.6), radius: 6, x: 0, y: 0)
        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
    }
}

// MARK: - Color tokens

private extension Color {
    /// Figma button fill — #FFEA9E.
    static let fabGold       = Color(red: 1.0, green: 234.0/255, blue: 158.0/255)
    /// Figma glow ring — #FAE287.
    static let fabGoldGlow   = Color(red: 250.0/255, green: 226.0/255, blue: 135.0/255)
    /// Figma icon color on gold — #00101A.
    static let fabIconColor  = Color(red: 0.0, green: 16.0/255, blue: 26.0/255)
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        HomeFloatingActionButton(onFabPencilTap: {}, onFabKudosTap: {})
    }
    .preferredColorScheme(.dark)
}
#endif
