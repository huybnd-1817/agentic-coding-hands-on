import SwiftUI

/// Top bar of the Home screen: brand logo left, language picker + search + bell
/// (with unread badge) right. Order mirrors MoMorph design OuH1BUTYT0
/// (language chip leads, then search, then notification).
struct HomeHeaderView: View {

    // MARK: - Inputs

    let unreadCount: Int

    @Binding var selectedLanguage: AppLanguage

    // MARK: - Outputs

    let onSearchTap: () -> Void
    let onBellTap: () -> Void
    let onLanguageChange: (AppLanguage) -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            // Brand logo — left anchor
            Image("sun-annual-awards")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 36)

            Spacer(minLength: 8)

            HStack(spacing: 16) {
                // Language picker — inline dropdown matching Login screen
                LanguagePicker(
                    selectedLanguage: $selectedLanguage,
                    onLanguageChange: onLanguageChange
                )
                .accessibilityIdentifier("home.header.language")
                .accessibilityLabel(Text(LocalizedStringKey("home.language.title")))

                // Search
                Button(action: onSearchTap) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(.white)
                }
                .accessibilityIdentifier("home.header.search")

                // Bell with optional unread badge
                Button(action: onBellTap) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(.white)

                        if unreadCount > 0 {
                            Circle()
                                .fill(Color.homeBadgeRed)
                                .frame(width: 8, height: 8)
                                .offset(x: 3, y: -3)
                                .accessibilityIdentifier("home.header.bell.badge")
                        }
                    }
                }
                .accessibilityIdentifier("home.header.bell")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

// MARK: - Color tokens

private extension Color {
    static let homeBadgeRed = Color(red: 1.0, green: 59.0/255, blue: 48.0/255)
}

// MARK: - Preview

#if DEBUG
private struct HomeHeaderPreviewHost: View {
    @State var lang: AppLanguage = .vi
    let unread: Int

    var body: some View {
        ZStack {
            Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
            HomeHeaderView(
                unreadCount: unread,
                selectedLanguage: $lang,
                onSearchTap: {},
                onBellTap: {},
                onLanguageChange: { _ in }
            )
        }
    }
}

#Preview("Unread = 3") {
    HomeHeaderPreviewHost(unread: 3)
}

#Preview("No badge") {
    HomeHeaderPreviewHost(unread: 0)
}
#endif
