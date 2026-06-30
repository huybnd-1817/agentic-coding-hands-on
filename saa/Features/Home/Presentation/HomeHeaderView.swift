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
                // Language picker — inline dropdown matching Login screen.
                // The chip identifier is passed THROUGH the LanguagePicker init
                // (not via an outer `.accessibilityIdentifier(...)`) because the
                // outer form propagates the identifier to descendant Buttons
                // (the dropdown rows), shadowing their `languagePicker.row.*`
                // identifiers and breaking
                // `HomeIntegrationUITests.testLanguagePickerOpensInlineDropdown`.
                LanguagePicker(
                    selectedLanguage: $selectedLanguage,
                    onLanguageChange: onLanguageChange,
                    chipAccessibilityIdentifier: "home.header.language"
                )

                // Search — Figma `mm_media_search` custom artwork.
                Button(action: onSearchTap) {
                    Image("kudos-icon-search")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                }
                .accessibilityIdentifier("home.header.search")

                // Bell with optional unread badge — Figma `mm_media_notification`.
                Button(action: onBellTap) {
                    ZStack(alignment: .topTrailing) {
                        Image("kudos-icon-notification")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
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
