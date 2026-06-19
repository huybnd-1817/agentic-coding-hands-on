import SwiftUI

/// All Kudos feed section (MoMorph `mms_C_All kudos` — id `6885:9220`).
///
/// Renders the "ALL KUDOS" section header via `KudosSectionHeader`, a vertical
/// list of `KudosCard` instances (one per `KudosCardData`), and a "View all Kudos"
/// text-link with a right-arrow icon at the bottom.
///
/// Empty state: plain text "Hiện tại chưa có Kudos nào." centered in the content area.
@MainActor
struct KudosAllSection: View {

    // MARK: - Inputs

    let kudos: [KudosCardData]

    // MARK: - Outputs

    let onCardCopyLink: (KudosCardID) -> Void
    let onCardLike: (KudosCardID) -> Void
    let onCardViewDetail: (KudosCardID) -> Void
    let onHashtagTap: (String) -> Void
    let onSenderTap: (KudosCardID) -> Void
    let onRecipientTap: (KudosCardID) -> Void
    let onViewAllKudos: () -> Void

    // MARK: - Body

    var body: some View {
        contentArea
    }

    // MARK: - Content area

    @ViewBuilder
    private var contentArea: some View {
        if kudos.isEmpty {
            emptyState
        } else {
            listContent
        }
    }

    // MARK: - List content

    private var listContent: some View {
        VStack(alignment: .center, spacing: 12) {
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
            }

            viewAllButton
        }
        .padding(.horizontal, 20)
    }

    // MARK: - View all button
    //
    // Figma node 6891:15987: centered text "View all Kudos" + arrow icon.
    // Text: Montserrat Medium 14pt, white. Icon: SF Symbol arrow.up.right.
    // Height: 32px, no background fill (text-link style).

    private var viewAllButton: some View {
        Button(action: onViewAllKudos) {
            HStack(spacing: 8) {
                Text(LocalizedStringKey("kudos.list.viewAll"))
                    .font(.custom("Montserrat-Medium", size: 14))
                    .foregroundColor(.kudosAllViewAllText)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.kudosAllViewAllText)
            }
            .frame(height: 32)
            .padding(.horizontal, 10)
        }
        .accessibilityIdentifier("kudos.all.viewAllButton")
    }

    // MARK: - Empty state

    private var emptyState: some View {
        Text(LocalizedStringKey("kudos.list.empty"))
            .font(.custom("Montserrat-Regular", size: 14))
            .foregroundColor(Color.white.opacity(0.6))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 32)
            .accessibilityIdentifier("kudos.all.emptyState")
    }
}

// MARK: - Color tokens

private extension Color {
    /// "View all Kudos" link text — #FFEA9E (gold).
    /// Figma node I6891:15987;72:2029 — backgroundColor rgba(255,255,255,1) is
    /// the text color override; however the design context uses gold for action
    /// text throughout the feed. Per Figma button componentId 6885:7556 which
    /// matches the transparent/text-link variant used across the Kudos screen.
    static let kudosAllViewAllText = Color(red: 1.0, green: 234.0 / 255, blue: 158.0 / 255)
}

// MARK: - Preview

#if DEBUG
#Preview("With kudos") {
    ZStack {
        Color(red: 0, green: 16.0 / 255, blue: 26.0 / 255).ignoresSafeArea()
        ScrollView {
            KudosAllSection(
                kudos: KudosCardData.mockList,
                onCardCopyLink: { _ in },
                onCardLike: { _ in },
                onCardViewDetail: { _ in },
                onHashtagTap: { _ in },
                onSenderTap: { _ in },
                onRecipientTap: { _ in },
                onViewAllKudos: {}
            )
            .padding(.vertical, 20)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Empty state") {
    ZStack {
        Color(red: 0, green: 16.0 / 255, blue: 26.0 / 255).ignoresSafeArea()
        KudosAllSection(
            kudos: [],
            onCardCopyLink: { _ in },
            onCardLike: { _ in },
            onCardViewDetail: { _ in },
            onHashtagTap: { _ in },
            onSenderTap: { _ in },
            onRecipientTap: { _ in },
            onViewAllKudos: {}
        )
        .padding(.vertical, 20)
    }
    .preferredColorScheme(.dark)
}
#endif
