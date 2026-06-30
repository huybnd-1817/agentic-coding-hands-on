import SwiftUI

// MARK: - AwardDetailView

/// Shared template for all 6 SAA 2025 award detail screens.
///
/// Layout (top → bottom):
///   1. `HomeHeaderView` — language picker, search, bell (reused from Home).
///   2. `KVKudosBanner` — compact recognition-system tagline + KUDOS logo.
///   3. `AwardHighlightBlock` — eyebrow + title + selector dropdown chip.
///   4. `AwardInfoBlock` — badge, title, description, quantity, prize row(s).
///   5. `AwardKudosPromoBlock` — Sun*Kudos promo with "Chi tiết" CTA.
///
/// The `AwardDetailViewModel` owns the selected award and the full awards list.
/// Switching via the dropdown calls `vm.select(_:)` which publishes back to here.
///
/// Background: #00101A, matching the Home screen canvas (shared `home-bg` artwork).
struct AwardDetailView: View {

    // MARK: - ViewModel

    @ObservedObject var vm: AwardDetailViewModel

    // MARK: - Environment

    @SwiftUI.Environment(\.locale) private var locale

    // MARK: - Header inputs

    let unreadCount: Int
    @Binding var selectedLanguage: AppLanguage

    // MARK: - Closures

    let onTapKudosCTA: () -> Void
    let onBellTap: () -> Void
    let onSearchTap: () -> Void
    let onLanguageChange: (AppLanguage) -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            HomeHeaderView(
                unreadCount: unreadCount,
                selectedLanguage: $selectedLanguage,
                onSearchTap: onSearchTap,
                onBellTap: onBellTap,
                onLanguageChange: onLanguageChange
            )
            // Lift header above the sibling ScrollView so the
            // LanguagePicker's overlay-rendered dropdown panel wins hit-tests.
            .zIndex(1)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    KVKudosBanner()

                    AwardHighlightBlock(
                        award: vm.selected,
                        awards: vm.awards,
                        onSelect: vm.select
                    )
                    // Lift above subsequent siblings (AwardInfoBlock,
                    // AwardKudosPromoBlock) so the selector dropdown panel
                    // is drawn ON TOP of them when open. Without this, the
                    // panel is obscured by later VStack siblings.
                    .zIndex(2)

                    AwardInfoBlock(award: vm.selected)

                    AwardKudosPromoBlock(onTapKudosCTA: onTapKudosCTA)

                    // Bottom padding clears the MainTabView-owned nav bar.
                    Spacer().frame(height: 100)
                }
                .padding(.top, 16)
            }
        }
        .background(backgroundLayer)
        .accessibilityIdentifier("award.detail.root")
        .preferredColorScheme(.dark)
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            // Figma frame fill — #00101A (shared with Home backdrop).
            Color(red: 0.0, green: 16.0/255, blue: 26.0/255)

            Image("home-bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Previews

#if DEBUG
private struct AwardDetailPreviewHost: View {
    let award: Award
    @State private var language: AppLanguage = .vi

    var body: some View {
        AwardDetailView(
            vm: AwardDetailViewModel(
                awards: HomeMockData.previewAwards,
                initiallySelected: award
            ),
            unreadCount: 3,
            selectedLanguage: $language,
            onTapKudosCTA: {},
            onBellTap: {},
            onSearchTap: {},
            onLanguageChange: { _ in }
        )
    }
}

#Preview("Top Talent") {
    AwardDetailPreviewHost(award: HomeMockData.previewAwards[0])
}

#Preview("Top Project") {
    AwardDetailPreviewHost(award: HomeMockData.previewAwards[1])
}

#Preview("Top Project Leader") {
    AwardDetailPreviewHost(award: HomeMockData.previewAwards[2])
}

#Preview("Best Manager") {
    AwardDetailPreviewHost(award: HomeMockData.previewAwards[3])
}

#Preview("Signature 2026 Creator — dual prize") {
    AwardDetailPreviewHost(award: HomeMockData.previewAwards[4])
}

#Preview("MVP") {
    AwardDetailPreviewHost(award: HomeMockData.previewAwards[5])
}
#endif
