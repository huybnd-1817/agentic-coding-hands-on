import SwiftUI

/// Reusable kudo card for both the Highlight carousel (mms_B.3, node `6885:9092`)
/// and the All Kudos feed. Matches Figma component `6885:8424`.
///
/// Anatomy (top → bottom, gap 8pt):
///   1. `trao nhận` row — `KudosCardPersonInfo` sender + arrow + recipient.
///   2. Gold 1pt divider.
///   3. Content block: timestamp · bold title · body quote box · hashtag row.
///   4. Gold 1pt divider.
///   5. Action row: heart count+icon | Copy Link | Xem chi tiết.
///
/// `bodyLineLimit` switches truncation: 3 lines for carousel, 5 for feed.
/// All tap targets fire typed callbacks; no internal state is held.
@MainActor
struct KudosCard: View {

    // MARK: - Inputs

    let data: KudosCardData
    var bodyLineLimit: Int = 3

    // MARK: - Outputs

    let onCopyLink: (KudosCardID) -> Void
    let onLike: (KudosCardID) -> Void
    let onViewDetail: (KudosCardID) -> Void
    let onHashtagTap: (String) -> Void
    let onSenderTap: (KudosCardID) -> Void
    let onRecipientTap: (KudosCardID) -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            traoNhanRow
            goldDivider
            contentBlock
            goldDivider
            actionRow
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.kudosCardBg)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.kudosCardGold, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityIdentifier("kudos.card.\(data.id)")
    }

    // MARK: - Trao nhận row

    private var traoNhanRow: some View {
        HStack(spacing: 8) {
            KudosCardPersonInfo(
                name: data.senderName, code: data.senderCode,
                role: data.senderRole, avatarAssetName: data.senderAvatarAssetName
            )
            .onTapGesture { onSenderTap(data.id) }

            directionArrow

            KudosCardPersonInfo(
                name: data.recipientName, code: data.recipientCode,
                role: data.recipientRole, avatarAssetName: data.recipientAvatarAssetName
            )
            .onTapGesture { onRecipientTap(data.id) }
        }
        .frame(height: 62)
    }

    private var directionArrow: some View {
        Group {
            if UIImage(named: "kudos-card-direction-arrow") != nil {
                Image("kudos-card-direction-arrow")
                    .resizable().renderingMode(.template)
                    .scaledToFit().foregroundColor(Color.kudosCardText)
            } else {
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .medium)).foregroundColor(Color.kudosCardText)
            }
        }
        .frame(width: 16, height: 16)
    }

    private var goldDivider: some View {
        Rectangle().fill(Color.kudosCardGold).frame(maxWidth: .infinity).frame(height: 1)
    }

    // MARK: - Content block

    private var contentBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(data.timestampText)
                .font(.custom("Montserrat-Medium", size: 10))
                .foregroundColor(Color.kudosCardSubtext).tracking(0.231)

            // Bold gold title centred — Figma fontWeight 700, color #00101A.
            Text(data.title)
                .font(.custom("Montserrat-Bold", size: 10))
                .foregroundColor(Color.kudosCardText).tracking(0.231)
                .frame(maxWidth: .infinity, alignment: .center)

            bodyQuoteBox
            hashtagRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bodyQuoteBox: some View {
        Text(data.body)
            .font(.custom("Montserrat-Regular", size: 10))
            .foregroundColor(Color.kudosCardText)
            .lineSpacing(4)
            .lineLimit(bodyLineLimit)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
            .background(Color.kudosCardGold.opacity(0.40))
            .overlay(RoundedRectangle(cornerRadius: 5.554).stroke(Color.kudosCardGold, lineWidth: 0.463))
            .clipShape(RoundedRectangle(cornerRadius: 5.554))
    }

    private var hashtagRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(data.hashtags, id: \.self) { tag in
                    Button { onHashtagTap(tag) } label: {
                        Text("#\(tag)")
                            .font(.custom("Montserrat-Regular", size: 10))
                            .foregroundColor(Color.kudosHashtagRed).tracking(0.231)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("kudos.card.hashtag.\(tag)")
                }
            }
        }
        .frame(height: 23)
    }

    // MARK: - Action row

    private var actionRow: some View {
        HStack {
            heartButton
            Spacer()
            copyLinkButton
            viewDetailButton
        }
        .frame(height: 24)
    }

    private var heartButton: some View {
        Button { onLike(data.id) } label: {
            HStack(spacing: 1.851) {
                Text(formattedHeartCount)
                    .font(.custom("Montserrat-Regular", size: 10))
                    .foregroundColor(Color.kudosCardText).monospacedDigit()
                Image(systemName: data.isLikedByMe ? "heart.fill" : "heart")
                    .font(.system(size: 12))
                    .foregroundColor(data.isLikedByMe ? .red : Color.kudosCardText)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(data.heartCount) hearts")
        .accessibilityIdentifier("kudos.card.heart")
    }

    private var copyLinkButton: some View {
        Button { onCopyLink(data.id) } label: {
            HStack(spacing: 4) {
                Text(LocalizedStringKey("kudos.card.copyLink"))
                    .font(.custom("Montserrat-Medium", size: 10))
                    .foregroundColor(Color.kudosCardText).tracking(0.069)
                Image(systemName: "link").font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.kudosCardText)
            }
            .padding(4).frame(height: 24).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("kudos.card.copyLink")
    }

    private var viewDetailButton: some View {
        Button { onViewDetail(data.id) } label: {
            HStack(spacing: 4) {
                Text(LocalizedStringKey("kudos.card.viewDetail"))
                    .font(.custom("Montserrat-Medium", size: 10))
                    .foregroundColor(Color.kudosCardText).tracking(0.069)
                Image("kudos-card-view-detail-arrow")
                    .resizable().renderingMode(.template)
                    .frame(width: 16, height: 16)
                    .foregroundColor(Color.kudosCardText)
            }
            .padding(4).frame(height: 24).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("kudos.card.viewDetail")
    }

    // MARK: - Helpers

    /// Vietnamese thousands formatting: 1000 → "1.000".
    private var formattedHeartCount: String {
        guard data.heartCount >= 1000 else { return "\(data.heartCount)" }
        let thousands = data.heartCount / 1000
        let remainder = data.heartCount % 1000
        return remainder == 0
            ? "\(thousands).000"
            : String(format: "%d.%03d", thousands, remainder)
    }
}

// MARK: - Color tokens

private extension Color {
    static let kudosCardBg      = Color(red: 1.0,         green: 248.0/255, blue: 225.0/255) // #FFF8E1
    static let kudosCardGold    = Color(red: 1.0,         green: 234.0/255, blue: 158.0/255) // #FFEA9E
    static let kudosCardText    = Color(red: 0.0,         green: 16.0/255,  blue: 26.0/255)  // #00101A
    static let kudosCardSubtext = Color(red: 153.0/255,   green: 153.0/255, blue: 153.0/255) // #999999
    static let kudosHashtagRed  = Color(red: 212.0/255,   green: 39.0/255,  blue: 29.0/255)  // #D4271D
}

// MARK: - Preview

#if DEBUG
#Preview("Highlight — 3-line body") {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        KudosCard(
            data: KudosCardData.mockList[0], bodyLineLimit: 3,
            onCopyLink: { _ in }, onLike: { _ in }, onViewDetail: { _ in },
            onHashtagTap: { _ in }, onSenderTap: { _ in }, onRecipientTap: { _ in }
        )
        .frame(width: 273).padding(20)
    }
    .preferredColorScheme(.dark)
}

#Preview("Feed — 5-line body") {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        KudosCard(
            data: KudosCardData.mockList[1], bodyLineLimit: 5,
            onCopyLink: { _ in }, onLike: { _ in }, onViewDetail: { _ in },
            onHashtagTap: { _ in }, onSenderTap: { _ in }, onRecipientTap: { _ in }
        )
        .padding(20)
    }
    .preferredColorScheme(.dark)
}
#endif
