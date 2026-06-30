import SwiftUI

// MARK: - Color tokens
// File-private copies so this file is self-contained and does not collide
// with the private tokens in `KudosView.swift`.

private extension Color {
    static let allKudosScreenBg = Color(red: 0, green: 16.0 / 255, blue: 26.0 / 255)  // #00101A
    static let allKudosGold = Color(red: 1.0, green: 234.0 / 255, blue: 158.0 / 255)  // #FFEA9E
}

// MARK: - AllKudosView

/// Full-screen "All Kudos" feed (MoMorph screen `j_a2GQWKDJ`).
/// Pure presentation — system nav bar is hidden by the parent container.
@MainActor
struct AllKudosView: View {

    // MARK: - Inputs

    let kudos: [KudosCardData]
    let isInitialLoading: Bool
    let isLoadingMore: Bool
    let hasMore: Bool

    // MARK: - Outputs

    let onBack: () -> Void
    let onCardLike: (KudosCardID) -> Void
    let onCardCopyLink: (KudosCardID) -> Void
    let onCardViewDetail: (KudosCardID) -> Void
    let onHashtagTap: (String) -> Void
    let onSenderTap: (KudosCardID) -> Void
    let onRecipientTap: (KudosCardID) -> Void
    /// Fires when the last card enters the viewport — triggers next page load.
    let onReachBottom: () -> Void
    /// `async` so `.refreshable` keeps the spinner visible until refetch ends.
    let onRefresh: () async -> Void

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            screenBackground

            VStack(spacing: 0) {
                navigationBar
                heroBlock
                AllKudosFeedList(
                    kudos: kudos,
                    isInitialLoading: isInitialLoading,
                    isLoadingMore: isLoadingMore,
                    hasMore: hasMore,
                    onCardLike: onCardLike,
                    onCardCopyLink: onCardCopyLink,
                    onCardViewDetail: onCardViewDetail,
                    onHashtagTap: onHashtagTap,
                    onSenderTap: onSenderTap,
                    onRecipientTap: onRecipientTap,
                    onReachBottom: onReachBottom,
                    onRefresh: onRefresh
                )
            }
        }
        .ignoresSafeArea(edges: .top)
        .accessibilityIdentifier("allKudos.root")
    }

    // MARK: - Screen background — mirrors KudosView.screenBackground

    private var screenBackground: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = width * 812.0 / 375.0

            ZStack(alignment: .top) {
                Color.allKudosScreenBg

                Image("kudos-hero-bg-group")
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height, alignment: .top)
                    .clipped()
            }
            .frame(width: width, height: proxy.size.height, alignment: .top)
        }
        .ignoresSafeArea()
    }

    // MARK: - Navigation bar (Figma 6891:16000)
    // 89pt total = 47pt status-bar spacer + 42pt content row, mirroring
    // `CreateKudoView`'s header geometry.

    private var navigationBar: some View {
        ZStack {
            Color.clear
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                Color.clear.frame(height: 47)

                HStack(spacing: 0) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .frame(width: 42, height: 42)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 7)
                    .accessibilityIdentifier("allKudos.backButton")

                    Spacer()

                    Text(LocalizedStringKey("kudos.allKudos.title"))
                        .font(.custom("Helvetica Neue", size: 17).weight(.medium))
                        .foregroundColor(.white)
                        .tracking(0.5)

                    Spacer()

                    // Mirror spacer for title centering.
                    Color.clear.frame(width: 42, height: 42)
                        .padding(.trailing, 7)
                }
                .frame(height: 42)
            }
        }
        .frame(height: 89)
    }

    // MARK: - Hero block (Figma 6891:16644 — eyebrow + separator + "ALL KUDOS" title)

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sun* Annual Awards 2025")
                .font(.custom("Montserrat-Regular", size: 12))
                .foregroundColor(.white.opacity(0.8))

            Rectangle()
                .fill(Color(red: 46.0 / 255, green: 57.0 / 255, blue: 64.0 / 255))
                .frame(height: 1)

            // Montserrat Medium 22pt (Figma node I6891:16644;75:1887).
            Text("ALL KUDOS")
                .font(.custom("Montserrat-Medium", size: 22))
                .foregroundColor(.allKudosGold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("With kudos") {
    AllKudosView(
        kudos: KudosCardData.mockList,
        isInitialLoading: false,
        isLoadingMore: false,
        hasMore: true,
        onBack: {},
        onCardLike: { _ in },
        onCardCopyLink: { _ in },
        onCardViewDetail: { _ in },
        onHashtagTap: { _ in },
        onSenderTap: { _ in },
        onRecipientTap: { _ in },
        onReachBottom: {},
        onRefresh: {}
    )
    .preferredColorScheme(.dark)
}

#Preview("Empty state") {
    AllKudosView(
        kudos: [],
        isInitialLoading: false,
        isLoadingMore: false,
        hasMore: false,
        onBack: {},
        onCardLike: { _ in },
        onCardCopyLink: { _ in },
        onCardViewDetail: { _ in },
        onHashtagTap: { _ in },
        onSenderTap: { _ in },
        onRecipientTap: { _ in },
        onReachBottom: {},
        onRefresh: {}
    )
    .preferredColorScheme(.dark)
}
#endif
