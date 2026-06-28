import SwiftUI

// MARK: - Color tokens

private extension Color {
    /// Figma screen background — #00101A (deep navy).
    /// File-private copy so AllKudosView.swift is self-contained and does not
    /// conflict with the private token in KudosView.swift.
    static let allKudosScreenBg = Color(red: 0, green: 16.0 / 255, blue: 26.0 / 255)

    /// Figma gold — #FFEA9E. Used for the "ALL KUDOS" hero title.
    static let allKudosGold = Color(red: 1.0, green: 234.0 / 255, blue: 158.0 / 255)
}

// MARK: - AllKudosView

/// Full-screen "All Kudos" feed (MoMorph `[iOS] Sun*Kudos_All Kudos` — screen `j_a2GQWKDJ`).
///
/// Layout (top → bottom):
///   1. Custom black header — back chevron + "All Kudos" title (system nav bar hidden by Phase 04).
///   2. Hero block — eyebrow "Sun* Annual Awards 2025" + gold "ALL KUDOS" title.
///   3. `AllKudosFeedList` — infinite-scroll `LazyVStack` of `KudosCard`s.
///
/// Background: `kudos-hero-bg-group` key-visual anchored at the top, fading into
/// `Color.allKudosScreenBg` — mirrors `KudosView.screenBackground`.
///
/// This view is static/presentational. All data and callbacks are injected as props;
/// no ViewModel is held here (Phase 04 owns integration).
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

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            screenBackground

            VStack(spacing: 0) {
                customHeader
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
                    onReachBottom: onReachBottom
                )
            }
        }
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

    // MARK: - Custom header (Figma 6891:16000 — Phase 04 hides system NavigationBar)

    private var customHeader: some View {
        HStack(spacing: 0) {
            // Back button — 44×44 tap area wrapping the 24pt icon.
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityIdentifier("allKudos.backButton")
            .padding(.leading, 4)

            Spacer()

            Text(LocalizedStringKey("kudos.allKudos.title"))
                .font(.custom("Montserrat-SemiBold", size: 17))
                .foregroundColor(.white)

            Spacer()

            // Invisible right-side balance placeholder (mirrors left button width).
            Color.clear
                .frame(width: 44 + 4, height: 44)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.allKudosScreenBg)
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

            Text("ALL KUDOS")
                .font(.custom("Montserrat-Bold", size: 32))
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
        onReachBottom: {}
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
        onReachBottom: {}
    )
    .preferredColorScheme(.dark)
}
#endif
