import SwiftUI

/// Horizontally-scrollable Awards section. Switches between loading skeleton,
/// loaded cards, empty state, and error+retry based on `awardsState`.
struct HomeAwardsSection: View {

    // MARK: - Inputs

    let awardsState: AwardsState

    // MARK: - Outputs

    let onAwardDetail: (UUID) -> Void
    let onRetryAwards: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HomeSectionHeader(
                eyebrowKey: "home.awards.eventLabel",
                titleKey: "home.awards.sectionTitle"
            )

            stateContent
        }
    }

    // MARK: - State switcher

    @ViewBuilder
    private var stateContent: some View {
        switch awardsState {
        case .loading:
            AwardsLoadingView()

        case .loaded(let awards):
            if awards.isEmpty {
                AwardsEmptyView()
            } else {
                loadedCardsView(awards: awards)
            }

        case .empty:
            AwardsEmptyView()

        case .error:
            AwardsErrorView(onRetry: onRetryAwards)
        }
    }

    // MARK: - Loaded cards
    //
    // Snap-paging carousel with peek of the next card.
    // iOS 17+: `.scrollTargetBehavior(.viewAligned)` snaps each card to the
    // leading edge; the trailing edge reveals the next card(s) and a peek.
    // iOS 16: falls back to free horizontal scroll — no regression.

    @ViewBuilder
    private func loadedCardsView(awards: [Award]) -> some View {
        if #available(iOS 17.0, *) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(awards) { award in
                        AwardCardView(award: award) {
                            onAwardDetail(award.id)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .scrollClipDisabled()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(awards) { award in
                        AwardCardView(award: award) {
                            onAwardDetail(award.id)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Loaded") {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        HomeAwardsSection(
            awardsState: .loaded(HomeMockData.previewAwards),
            onAwardDetail: { _ in },
            onRetryAwards: {}
        )
        .padding(.vertical, 20)
    }
    .preferredColorScheme(.dark)
}

#Preview("Loading") {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        HomeAwardsSection(
            awardsState: .loading,
            onAwardDetail: { _ in },
            onRetryAwards: {}
        )
        .padding(.vertical, 20)
    }
    .preferredColorScheme(.dark)
}

#Preview("Empty") {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        HomeAwardsSection(
            awardsState: .empty,
            onAwardDetail: { _ in },
            onRetryAwards: {}
        )
        .padding(.vertical, 20)
    }
    .preferredColorScheme(.dark)
}

#Preview("Error") {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        HomeAwardsSection(
            awardsState: .error(.network),
            onAwardDetail: { _ in },
            onRetryAwards: {}
        )
        .padding(.vertical, 20)
    }
    .preferredColorScheme(.dark)
}
#endif
