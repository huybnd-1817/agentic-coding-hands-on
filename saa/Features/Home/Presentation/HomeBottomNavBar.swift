import SwiftUI

/// Bottom navigation bar with 4 tabs: SAA 2025 / Awards / Kudos / Profile.
/// Active tab is highlighted in brand-gold; inactive tabs are dimmed white.
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
        .padding(.top, 10)
        .padding(.bottom, 4)
        .background(Color.navBarBackground)
        .overlay(
            Rectangle()
                .fill(Color.navBarBorder)
                .frame(height: 1),
            alignment: .top
        )
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

                Text(tab.rawValue)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
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
    static let navBarBackground = Color(red: 0.02, green: 0.06, blue: 0.10)
    static let navBarBorder     = Color(red: 153.0/255, green: 140.0/255, blue: 95.0/255).opacity(0.3)
    static let navActiveGold    = Color(red: 1.0, green: 234.0/255, blue: 158.0/255)
    static let navInactive      = Color.white.opacity(0.45)
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
