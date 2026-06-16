import SwiftUI

/// Floating action button cluster: pencil (write kudo) + S/Kudos badge.
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
        VStack(spacing: 12) {
            // S/Kudos label badge
            Button(action: onFabKudosTap) {
                Text(LocalizedStringKey("home.kudos.newBadge"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.fabGold)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .accessibilityIdentifier("home.fab.kudos")

            // Primary pencil button
            Button(action: onFabPencilTap) {
                Image(systemName: "pencil")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 52, height: 52)
                    .background(Color.fabGold)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 3)
            }
            .accessibilityIdentifier("home.fab.pencil")
        }
    }
}

// MARK: - Color tokens

private extension Color {
    static let fabGold = Color(red: 1.0, green: 234.0/255, blue: 158.0/255)
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
