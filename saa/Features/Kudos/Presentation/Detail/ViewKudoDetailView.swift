import SwiftUI

// MARK: - Color tokens (file-private)

private extension Color {
    static let detailScreenBg   = Color(red: 0,          green: 16.0/255,  blue: 26.0/255)  // #00101A
    static let detailCardBg     = Color(red: 1.0,        green: 248.0/255, blue: 225.0/255) // #FFF8E1
    static let detailGold       = Color(red: 1.0,        green: 234.0/255, blue: 158.0/255) // #FFEA9E
    static let detailText       = Color(red: 0,          green: 16.0/255,  blue: 26.0/255)  // #00101A
    static let detailSubtext    = Color(red: 153.0/255,  green: 153.0/255, blue: 153.0/255) // #999999
    static let detailHashtagRed = Color(red: 212.0/255,  green: 39.0/255,  blue: 29.0/255)  // #D4271D
}

// MARK: - ViewKudoDetailView

/// Detail screen for a single kudo (MoMorph screen `T0TR16k0vH`).
/// Pure presentation — all data and callbacks injected as props.
@MainActor
struct ViewKudoDetailView: View {

    // MARK: - Inputs

    let kudos: Kudos
    /// Department code lookup (matches `KudosCard`'s resolution). Default
    /// keeps previews simple; production threads `KudosViewModel.departments`.
    var departments: [UUID: Department] = [:]
    /// `storagePath` → signed URL map (the `kudos-images` bucket is private).
    /// Empty during initial render, refreshed once signing completes.
    var resolvedImageURLs: [String: URL] = [:]

    // MARK: - Outputs

    let onBack: () -> Void
    let onLike: () -> Void
    let onCopyLink: () -> Void
    let onHashtagTap: (String) -> Void
    let onSenderTap: () -> Void
    let onRecipientTap: () -> Void
    let onImageTap: (Int) -> Void

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            screenBackground
            VStack(spacing: 0) {
                navigationBar
                ScrollView {
                    kudoCard
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                }
                // Identifier on ScrollView (not outer ZStack) so SwiftUI's
                // identifier-propagation does not shadow `kudos.detail.back`.
                .accessibilityIdentifier("kudos.detail.root")
                HomeBottomNavBar(selectedTab: .kudos, onTabTap: { _ in })
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Screen background (mirrors AllKudosView.screenBackground)

    var screenBackground: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            ZStack(alignment: .top) {
                Color.detailScreenBg
                Image("kudos-hero-bg-group")
                    .resizable().scaledToFill()
                    .frame(width: w, height: w * 812.0 / 375.0, alignment: .top).clipped()
            }
            .frame(width: w, height: proxy.size.height, alignment: .top)
        }
        .ignoresSafeArea()
    }

    // MARK: - Navigation bar (Figma 6885:10133/10135 — 47pt status + 42pt content = 89pt)

    var navigationBar: some View {
        ZStack {
            Color.clear.ignoresSafeArea(edges: .top)
            VStack(spacing: 0) {
                Color.clear.frame(height: 47)
                HStack(spacing: 0) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                            .frame(width: 24, height: 24).frame(width: 42, height: 42)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain).padding(.leading, 7)
                    .accessibilityIdentifier("kudos.detail.back")
                    Spacer()
                    Text(LocalizedStringKey("kudos.detail.title"))
                        .font(.custom("Helvetica Neue", size: 17).weight(.medium))
                        .foregroundColor(.white).tracking(0.5)
                    Spacer()
                    Color.clear.frame(width: 42, height: 42).padding(.trailing, 7)
                }
                .frame(height: 42)
            }
        }
        .frame(height: 89)
    }
}

// MARK: - Card subviews

extension ViewKudoDetailView {

    // Full card shell (B.3 + B.4 anatomy).
    var kudoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            traoNhanRow
            goldDivider
            contentBlock
            goldDivider
            actionBar
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Color.detailCardBg)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.detailGold, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // B.3 — sender → recipient highlight row.
    var traoNhanRow: some View {
        HStack(spacing: 0) {
            KudosCardPersonInfo(
                name: kudos.sender.displayName,
                code: KudosCardAdapter.codeLabel(for: kudos.sender, departments: departments),
                starTier: StarTier.from(received: kudos.sender.kudosReceivedCount),
                avatarURL: kudos.sender.avatarURL,
                subtitle: kudos.isAnonymous
                    ? LocalizedStringKey("kudos.anonymousSender.label")
                    : nil
            )
            .onTapGesture { onSenderTap() }
            .accessibilityIdentifier("kudos.detail.sender.button")
            Spacer(minLength: 0)
            directionArrow
            Spacer(minLength: 0)
            KudosCardPersonInfo(
                name: kudos.recipient.displayName,
                code: KudosCardAdapter.codeLabel(for: kudos.recipient, departments: departments),
                starTier: StarTier.from(received: kudos.recipient.kudosReceivedCount),
                avatarURL: kudos.recipient.avatarURL
            )
            .onTapGesture { onRecipientTap() }
            .accessibilityIdentifier("kudos.detail.recipient.button")
        }
        .frame(maxWidth: .infinity).frame(height: 62)
    }

    /// Mirrors `KudosCard.directionArrow` — bespoke asset with SF Symbol fallback.
    var directionArrow: some View {
        Group {
            if UIImage(named: "kudos-card-direction-arrow") != nil {
                Image("kudos-card-direction-arrow")
                    .resizable().renderingMode(.template)
                    .scaledToFit().foregroundColor(Color.detailText)
            } else {
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.detailText)
            }
        }
        .frame(width: 16, height: 16)
    }

    var goldDivider: some View {
        Rectangle().fill(Color.detailGold).frame(maxWidth: .infinity).frame(height: 1)
    }

    // B.4 — timestamp · title · message · gallery · hashtags.
    var contentBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formattedTimestamp)
                .font(.custom("Montserrat-Medium", size: 10))
                .foregroundColor(Color.detailSubtext).tracking(0.231)
            Text(kudos.title.uppercased())
                .font(.custom("Montserrat-Bold", size: 10))
                .foregroundColor(Color.detailText).tracking(0.231)
                .frame(maxWidth: .infinity, alignment: .center)
            messageQuoteBox
            if !kudos.attachments.isEmpty { imageGallery }
            if !kudos.hashtags.isEmpty { hashtagRow }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // B.4.2 — full message, no line-limit cap.
    var messageQuoteBox: some View {
        Text(kudos.message)
            .font(.custom("Montserrat-Regular", size: 10))
            .foregroundColor(Color.detailText).lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
            .background(Color.detailGold.opacity(0.40))
            .overlay(RoundedRectangle(cornerRadius: 5.554).stroke(Color.detailGold, lineWidth: 0.463))
            .clipShape(RoundedRectangle(cornerRadius: 5.554))
    }

    // F.2 — horizontal thumbnail gallery, 32x32pt per image. Two render paths:
    // legacy HTTPS URLs render immediately; bucket-relative paths require a
    // signed URL via `resolvedImageURLs` (populated asynchronously).
    var imageGallery: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(kudos.attachments.enumerated()), id: \.element.storagePath) { idx, att in
                    Button { onImageTap(idx) } label: {
                        AsyncImage(url: imageURL(for: att)) { phase in
                            if let img = phase.image { img.resizable().scaledToFill() }
                            else { Color.detailGold.opacity(0.2) }
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 1.787))
                        .overlay(RoundedRectangle(cornerRadius: 1.787).stroke(Color.detailGold, lineWidth: 0.447))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("kudos.detail.gallery.image.\(idx)")
                }
            }
        }
    }

    /// Prefers a resolved signed URL; falls back to direct HTTPS parse.
    func imageURL(for attachment: KudosAttachment) -> URL? {
        resolvedImageURLs[attachment.storagePath]
            ?? Self.directHTTPURL(from: attachment.storagePath)
    }

    /// `static nonisolated` so unit tests can call without instantiating the
    /// View — parse touches no UI state.
    nonisolated static func directHTTPURL(from storagePath: String) -> URL? {
        guard let url = URL(string: storagePath),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else { return nil }
        return url
    }

    // B.4.3 — wraps via shared `FlowLayout`; same shape as `KudosCard`.
    var hashtagRow: some View {
        FlowLayout(spacing: 4) {
            ForEach(kudos.hashtags, id: \.id) { hashtag in
                Button { onHashtagTap(hashtag.tag) } label: {
                    Text(hashtag.tag)
                        .font(.custom("Montserrat-Regular", size: 10))
                        .foregroundColor(Color.detailHashtagRed).tracking(0.231).lineLimit(1)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("kudos.detail.hashtag.\(hashtag.tag)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // B.4.4 — heart + Copy Link only (no "Xem chi tiết" — we are the detail screen).
    var actionBar: some View {
        HStack {
            Button(action: onLike) {
                HStack(spacing: 1.851) {
                    Text(formattedHeartCount)
                        .font(.custom("Montserrat-Regular", size: 10))
                        .foregroundColor(Color.detailText).monospacedDigit()
                    Image(systemName: kudos.isLikedByMe ? "heart.fill" : "heart")
                        .font(.system(size: 12))
                        .foregroundColor(kudos.isLikedByMe ? .red : Color.detailText)
                }
            }
            .buttonStyle(.plain).disabled(!kudos.canLike).opacity(kudos.canLike ? 1.0 : 0.4)
            .accessibilityLabel("\(kudos.heartCount) hearts")
            .accessibilityIdentifier("kudos.detail.heart")
            Spacer()
            Button(action: onCopyLink) {
                HStack(spacing: 4) {
                    Text(LocalizedStringKey("kudos.card.copyLink"))
                        .font(.custom("Montserrat-Medium", size: 10))
                        .foregroundColor(Color.detailText).tracking(0.069)
                    Image(systemName: "link").font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.detailText)
                }
                .padding(4).frame(height: 24).contentShape(Rectangle())
            }
            .buttonStyle(.plain).accessibilityIdentifier("kudos.detail.copyLink")
        }
        .frame(height: 24)
    }

    // MARK: - Formatting helpers

    /// "HH:mm - MM/dd/yyyy" matches Figma B.4.1 text "10:00 - 10/30/2025".
    var formattedTimestamp: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm - MM/dd/yyyy"
        return f.string(from: kudos.createdAt)
    }

    /// Vietnamese thousands format: 1000 → "1.000" (mirrors KudosCard).
    var formattedHeartCount: String {
        guard kudos.heartCount >= 1000 else { return "\(kudos.heartCount)" }
        let t = kudos.heartCount / 1000, r = kudos.heartCount % 1000
        return r == 0 ? "\(t).000" : String(format: "%d.%03d", t, r)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("View Kudo Detail") {
    // Figma-sourced mock: B.4.2 body, B.4.3 hashtags, Figma sender/recipient names.
    let kudos = Kudos(
        id: UUID(),
        sender: KudosAuthor(
            userId: UUID(uuidString: "aaaaaaaa-0000-0000-0000-000000000001")!,
            displayName: "Huỳnh Dương Xuân...", employeeCode: "CECV10",
            avatarURL: nil, departmentId: nil, kudosReceivedCount: 42
        ),
        recipient: KudosAuthor(
            userId: UUID(uuidString: "bbbbbbbb-0000-0000-0000-000000000002")!,
            displayName: "Dương Xuân Huỳnh...", employeeCode: "CECV10",
            avatarURL: nil, departmentId: nil, kudosReceivedCount: 120
        ),
        title: "NGƯỜI HÙNG CỦA LÒNG EM",
        message: "Cảm ơn người em bình thường nhưng phi thường :D Cảm ơn sự chăm chỉ, cần mẫn của em đã tạo động lực rất nhiều cho team, để luôn nhắc mình luôn phải nỗ lực hơn nữa trong công việc. <3 và cuộc sống",
        isAnonymous: false, anonymousNickname: nil,
        hashtags: [
            Hashtag(id: UUID(), tag: "#Dedicated"),
            Hashtag(id: UUID(), tag: "#Inspiring")
        ],
        attachments: [],
        heartCount: 10, isLikedByMe: false, canLike: true, shareURL: nil,
        createdAt: Date(timeIntervalSince1970: 1_730_257_200) // 10:00 10/30/2025 +07
    )
    ViewKudoDetailView(
        kudos: kudos, onBack: {}, onLike: {}, onCopyLink: {},
        onHashtagTap: { _ in }, onSenderTap: {}, onRecipientTap: {}, onImageTap: { _ in }
    )
    .preferredColorScheme(.dark)
}
#endif
