import SwiftUI

/// Top bar of the Home screen: brand logo left, search + bell (with unread badge)
/// + language picker right. Extracted verbatim from MoMorph design.
struct HomeHeaderView: View {

    // MARK: - Inputs

    let unreadCount: Int

    // MARK: - Outputs

    let onSearchTap: () -> Void
    let onBellTap: () -> Void
    let onLanguageTap: () -> Void

    // MARK: - Environment

    // Qualified to disambiguate from the project-local `enum Environment`.
    @SwiftUI.Environment(\.locale) private var locale

    private var languageBadge: String {
        locale.language.languageCode?.identifier == "vi" ? "VN" : "EN"
    }

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

                // Language picker — taps open the LanguageSelectionSheet
                Button(action: onLanguageTap) {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white)
                        Text(languageBadge)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .accessibilityIdentifier("home.header.language")
                .accessibilityLabel(Text(LocalizedStringKey("home.language.title")))
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
#Preview("Unread = 3") {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        HomeHeaderView(unreadCount: 3, onSearchTap: {}, onBellTap: {}, onLanguageTap: {})
    }
}

#Preview("No badge") {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        HomeHeaderView(unreadCount: 0, onSearchTap: {}, onBellTap: {}, onLanguageTap: {})
    }
}
#endif
