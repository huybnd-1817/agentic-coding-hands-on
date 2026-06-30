import SwiftUI

/// All Kudos infinite-scroll list. `onReachBottom` is id-gated so it fires
/// at most once per last-item identity.
@MainActor
struct AllKudosFeedList: View {

    // MARK: - Inputs

    let kudos: [KudosCardData]
    /// True while the first page is in flight; distinct from `isLoadingMore`
    /// so the empty-state copy doesn't flash before the first page resolves.
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
    /// `.refreshable` awaits this; the spinner stays until it returns.
    let onRefresh: () async -> Void

    // MARK: - Internal state

    /// Last card id we've already fired `onReachBottom` for — prevents
    /// duplicate fires when the cell re-enters the viewport on scroll-up.
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
            // Horizontal 50pt — Figma node 6891:16170 (startX=51).
            .padding(.horizontal, 50)
            // 80pt clears HomeBottomNavBar (~56pt) + 24pt breathing room.
            .padding(.bottom, 80)
        }
        .refreshable { await onRefresh() }
    }

    // MARK: - Initial loading indicator
    // Replaces the empty-state copy during the first-page fetch.

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
