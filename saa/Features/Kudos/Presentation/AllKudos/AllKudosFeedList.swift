import SwiftUI

/// Scrollable feed of `KudosCard` items for the All Kudos screen.
///
/// Responsibilities:
/// - Renders each card via `KudosCard(bodyLineLimit: 5)`.
/// - Fires `onReachBottom` once per page boundary when the last card's
///   `.onAppear` triggers (id-gated so it only fires once per last-item identity).
/// - Shows a centered `ProgressView` below the last card while `isLoadingMore`.
/// - Shows an empty-state label when the list is empty and not loading.
@MainActor
struct AllKudosFeedList: View {

    // MARK: - Inputs

    let kudos: [KudosCardData]
    /// True while the FIRST page is in flight (allFeedLoadState == .loading).
    /// Distinct from `isLoadingMore`: the initial load swaps the placeholder for a
    /// centered spinner so the empty-state copy doesn't flash before the first page
    /// resolves.
    let isInitialLoading: Bool
    let isLoadingMore: Bool
    let hasMore: Bool

    // MARK: - Outputs

    let onCardLike: (KudosCardID) -> Void
    let onCardCopyLink: (KudosCardID) -> Void
    let onCardViewDetail: (KudosCardID) -> Void
    let onHashtagTap: (String) -> Void
    let onSenderTap: (KudosCardID) -> Void
    let onRecipientTap: (KudosCardID) -> Void
    let onReachBottom: () -> Void
    /// Awaited by SwiftUI's `.refreshable` — the pull-to-refresh spinner stays
    /// visible until this returns.
    let onRefresh: () async -> Void

    // MARK: - Internal state

    /// Tracks the ID of the last card we already fired `onReachBottom` for.
    /// Prevents duplicate fires when the cell re-enters the viewport on scroll-up.
    @State private var lastFiredBottomID: KudosCardID?

    // MARK: - Body

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 16) {
                if !kudos.isEmpty {
                    feedCards
                } else if isInitialLoading {
                    initialLoadingIndicator
                } else {
                    emptyState
                }

                if !kudos.isEmpty && hasMore && isLoadingMore {
                    loadingIndicator
                }
            }
            // Horizontal 50pt — matches Figma node "Danh sách Kudo" (6891:16170)
            // which lays out at startX=51 / endX=324 on the 375pt artboard.
            .padding(.horizontal, 50)
            // Bottom 80pt = ~56pt visible HomeBottomNavBar content + 24pt
            // breathing room between the last card and the tab-bar's top edge.
            .padding(.bottom, 80)
        }
        .refreshable { await onRefresh() }
    }

    // MARK: - Initial loading indicator
    //
    // Shown when the first page is in flight and `allFeed` is still empty.
    // Replaces the empty-state copy so the user does not see "No kudos yet"
    // during the network round-trip.

    private var initialLoadingIndicator: some View {
        ProgressView()
            .tint(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 48)
            .accessibilityIdentifier("allKudos.loading")
    }

    // MARK: - Feed cards

    @ViewBuilder
    private var feedCards: some View {
        ForEach(kudos) { card in
            KudosCard(
                data: card,
                bodyLineLimit: 5,
                onCopyLink: onCardCopyLink,
                onLike: onCardLike,
                onViewDetail: onCardViewDetail,
                onHashtagTap: onHashtagTap,
                onSenderTap: onSenderTap,
                onRecipientTap: onRecipientTap
            )
            .onAppear {
                guard card.id == kudos.last?.id,
                      lastFiredBottomID != card.id else { return }
                lastFiredBottomID = card.id
                onReachBottom()
            }
        }
    }

    // MARK: - Loading indicator

    private var loadingIndicator: some View {
        ProgressView()
            .tint(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .accessibilityIdentifier("allKudos.loadingMore")
    }

    // MARK: - Empty state

    private var emptyState: some View {
        Text(LocalizedStringKey("kudos.list.empty"))
            .font(.custom("Montserrat-Regular", size: 14))
            .foregroundColor(Color.white.opacity(0.6))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 48)
            .accessibilityIdentifier("allKudos.emptyState")
    }
}

// MARK: - Color tokens (preview-only — production callers use Color(red:green:blue:) inline)

#if DEBUG
private extension Color {
    /// Deep navy #00101A — mirrors KudosView's private token.
    static let allKudosPreviewBg = Color(red: 0, green: 16.0 / 255, blue: 26.0 / 255)
}
#endif

// MARK: - Preview

#if DEBUG
#Preview("Feed list — with kudos") {
    ZStack {
        Color.allKudosPreviewBg.ignoresSafeArea()
        AllKudosFeedList(
            kudos: KudosCardData.mockList,
            isInitialLoading: false,
            isLoadingMore: false,
            hasMore: true,
            onCardLike: { _ in },
            onCardCopyLink: { _ in },
            onCardViewDetail: { _ in },
            onHashtagTap: { _ in },
            onSenderTap: { _ in },
            onRecipientTap: { _ in },
            onReachBottom: {},
            onRefresh: {}
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Feed list — empty") {
    ZStack {
        Color.allKudosPreviewBg.ignoresSafeArea()
        AllKudosFeedList(
            kudos: [],
            isInitialLoading: false,
            isLoadingMore: false,
            hasMore: false,
            onCardLike: { _ in },
            onCardCopyLink: { _ in },
            onCardViewDetail: { _ in },
            onHashtagTap: { _ in },
            onSenderTap: { _ in },
            onRecipientTap: { _ in },
            onReachBottom: {},
            onRefresh: {}
        )
    }
    .preferredColorScheme(.dark)
}
#endif
