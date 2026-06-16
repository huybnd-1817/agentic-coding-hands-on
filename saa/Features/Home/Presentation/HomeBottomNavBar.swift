import SwiftUI

/// Bottom navigation bar (MoMorph `mms_7_nav bar` — id `6885:9056`).
///
/// Solid dark gold-tinted capsule with rounded top corners, hosting 4 tab
/// buttons. The active tab's icon + label render in brand gold; inactive tabs
/// use white. Lives at `MainTabView` level so it's shared across all tab
/// destinations.
///
/// The background shape ignores the bottom safe area so the bar reaches the
/// screen edge instead of floating above the home indicator. The 20pt rounded
/// corners stay on the top edge; the bottom edge runs straight to the screen
/// bottom.
struct HomeBottomNavBar: View {

    // MARK: - Inputs

    let selectedTab: NavTab

    // MARK: - Outputs

    let onTabTap: (NavTab) -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            ForEach(NavTab.allCases) { tab in
                tabItem(tab)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 20
            )
            .fill(Color.navBarSolid)
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }

    // MARK: - Tab item

    private func tabItem(_ tab: NavTab) -> some View {
        let isSelected = tab == selectedTab

        return Button {
            onTabTap(tab)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .navActiveGold : .navInactive)
                    .frame(width: 24, height: 24)

                Text(tab.rawValue)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(isSelected ? .navActiveGold : .navInactive)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.nav.\(tab.id.lowercased())")
    }
}

// MARK: - Color tokens

private extension Color {
    /// Solid bar fill — the opaque equivalent of Figma's
    /// rgba(255, 234, 158, 0.15) blended over the screen's #00101A
    /// background: ≈ rgb(38, 49, 46) = #26312E.
    static let navBarSolid   = Color(red: 38.0/255, green: 49.0/255, blue: 46.0/255)
    /// Figma active label/icon — #FFEA9E.
    static let navActiveGold = Color(red: 1.0, green: 234.0/255, blue: 158.0/255)
    /// Figma inactive label — solid white per spec.
    static let navInactive   = Color.white
}

// MARK: - Preview

#if DEBUG
#Preview("Home selected") {
    ZStack(alignment: .bottom) {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        HomeBottomNavBar(selectedTab: .home, onTabTap: { _ in })
    }
    .preferredColorScheme(.dark)
}

#Preview("Awards selected") {
    ZStack(alignment: .bottom) {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        HomeBottomNavBar(selectedTab: .awards, onTabTap: { _ in })
    }
    .preferredColorScheme(.dark)
}
#endif
