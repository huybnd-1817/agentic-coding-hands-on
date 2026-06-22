import SwiftUI

// MARK: - KudosView

/// Root Sun*Kudos screen assembly for SAA 2025 (MoMorph `[iOS] Sun*Kudos` —
/// screen `fO0Kt19sZZ`).
///
/// Background layering (bottom → top):
///   1. Screen base color #00101A.
///   2. Full-bleed key-visual (`kudos-hero-keyvisual`) anchored to the top-right
///      — mirrors Figma `mm_media_bg` (6885:9060) which is a 1130×812 artwork
///      pinned to the right edge of the 375pt canvas. The header sits directly
///      over this artwork (transparent), and a top-down dark gradient fades the
///      KV into the navy base as the page scrolls.
///   3. Scrollable content: hero text → send button → highlight carousel →
///      spotlight stub → "ALL KUDOS" group (stats / secret box / top10 / feed).
///
/// Filter dropdowns are NOT mounted here — they're anchored directly under each
/// filter chip inside `KudosHighlightSection` via `.overlay(alignment: .topLeading)`.
struct KudosView: View {

    // MARK: - State surfaces (mock defaults — Phase 07 will bind to KudosViewModel)

    var highlights: [KudosCardData]              = KudosCardData.mockList
    var feed: [KudosCardData]                    = KudosCardData.mockList
    var hashtagOptions: [HashtagOption]          = KudosView.defaultHashtagOptions
    var departmentOptions: [DepartmentOption]    = KudosView.defaultDepartmentOptions
    var stats: KudosPersonalStatsData            = .mock
    var topRecipients: [KudosRecipientData]      = KudosRecipientData.mockList
    var showFireBadge: Bool                      = true
    var unreadCount: Int                         = 0

    // MARK: - Bindings

    @Binding var selectedLanguage: AppLanguage
    @Binding var carouselIndex: Int
    @Binding var selectedHashtag: HashtagOption?
    @Binding var selectedDepartment: DepartmentOption?
    @Binding var isHashtagSheetPresented: Bool
    @Binding var isDepartmentSheetPresented: Bool

    // MARK: - Action closures (default no-op for previewability)

    var onLanguageChange: (AppLanguage) -> Void       = { _ in }
    var onSearchTap:      () -> Void                  = {}
    var onBellTap:        () -> Void                  = {}
    var onSendKudos:      () -> Void                  = {}
    var onCardCopyLink:   (KudosCardID) -> Void       = { _ in }
    var onCardLike:       (KudosCardID) -> Void       = { _ in }
    var onCardViewDetail: (KudosCardID) -> Void       = { _ in }
    var onHashtagTagTap:  (String) -> Void            = { _ in }
    var onSenderTap:      (KudosCardID) -> Void       = { _ in }
    var onRecipientTap:   (KudosCardID) -> Void       = { _ in }
    var onTopRecipientTap:(KudosRecipientData.ID) -> Void = { _ in }
    var onOpenSecretBox:  () -> Void                  = {}
    var onViewAllKudos:   () -> Void                  = {}
    var onSelectHashtag:  (HashtagOption.ID) -> Void  = { _ in }
    var onSelectDepartment: (DepartmentOption.ID) -> Void = { _ in }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            screenBackground

            VStack(spacing: 0) {
                HomeHeaderView(
                    unreadCount: unreadCount,
                    selectedLanguage: $selectedLanguage,
                    onSearchTap: onSearchTap,
                    onBellTap: onBellTap,
                    onLanguageChange: onLanguageChange
                )
                .background(Color.clear)
                .zIndex(1)

                scrollContent
            }
        }
        .accessibilityIdentifier("kudos.root")
    }

    // MARK: - Screen background (key-visual with pre-baked gradient overlays)
    //
    // `kudos-hero-bg-group` is the Figma `mm_media_bg` (6885:9060) exported as
    // a single 375×812 PNG with Shadow Left + Shadow Bottom already composited
    // onto the key-visual. Scale to the full device width so the design's
    // 375pt proportions are preserved on every iPhone (393pt iPhone 15,
    // 430pt Pro Max, etc.). Below the image the navy base color continues to
    // fill the remainder of the (very tall) screen content.

    private var screenBackground: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = width * 812.0 / 375.0

            ZStack(alignment: .top) {
                Color.kudosScreenBackground

                Image("kudos-hero-bg-group")
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height, alignment: .top)
                    .clipped()
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        }
        .ignoresSafeArea()
    }

    // MARK: - Scrollable content

    private var scrollContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                KudosHeroSection()

                KudosSendButton(onTap: onSendKudos)
                    .padding(.horizontal, 20)

                KudosHighlightSection(
                    highlights: highlights,
                    selectedHashtag: selectedHashtag,
                    selectedDepartment: selectedDepartment,
                    hashtagOptions: hashtagOptions,
                    departmentOptions: departmentOptions,
                    carouselIndex: $carouselIndex,
                    isHashtagSheetPresented: $isHashtagSheetPresented,
                    isDepartmentSheetPresented: $isDepartmentSheetPresented,
                    onCardCopyLink: onCardCopyLink,
                    onCardLike: onCardLike,
                    onCardViewDetail: onCardViewDetail,
                    onHashtagTagTap: onHashtagTagTap,
                    onSenderTap: onSenderTap,
                    onRecipientTap: onRecipientTap,
                    onSelectHashtag: onSelectHashtag,
                    onSelectDepartment: onSelectDepartment
                )

                KudosSpotlightStubSection()
                    .padding(.horizontal, 20)

                allKudosGroup
            }
            .padding(.bottom, 100)
        }
    }

    // MARK: - All Kudos group (single section header + stats/secret/top10/feed)

    private var allKudosGroup: some View {
        VStack(alignment: .leading, spacing: 24) {
            KudosSectionHeader(subtitle: "kudos.section.subtitle", title: "kudos.section.all")
                .padding(.horizontal, 20)

            KudosPersonalStatsSection(
                stats: stats,
                showFireBadge: showFireBadge,
                onOpenSecretBox: onOpenSecretBox
            )
            .padding(.horizontal, 20)

            KudosTopRecipientsSection(
                recipients: topRecipients,
                onRecipientTap: onTopRecipientTap
            )
            .padding(.horizontal, 20)

            KudosAllSection(
                kudos: feed,
                onCardCopyLink: onCardCopyLink,
                onCardLike: onCardLike,
                onCardViewDetail: onCardViewDetail,
                onHashtagTap: onHashtagTagTap,
                onSenderTap: onSenderTap,
                onRecipientTap: onRecipientTap,
                onViewAllKudos: onViewAllKudos
            )
        }
    }

    // MARK: - Default filter options (mock — Phase 07 will replace with VM data)

    private static let defaultHashtagOptions: [HashtagOption] = [
        HashtagOption(label: "#Dedicated"),
        HashtagOption(label: "#Inspring"),
        HashtagOption(label: "#Teamwork"),
        HashtagOption(label: "#Helpful"),
        HashtagOption(label: "#Idol")
    ]

    private static let defaultDepartmentOptions: [DepartmentOption] = [
        DepartmentOption(label: "CEVC1"),
        DepartmentOption(label: "CEVC2"),
        DepartmentOption(label: "CEVC3"),
        DepartmentOption(label: "CEVC4"),
        DepartmentOption(label: "OPD"),
        DepartmentOption(label: "Infra")
    ]
}

// MARK: - Color tokens

private extension Color {
    /// Figma screen background — #00101A (deep navy).
    static let kudosScreenBackground = Color(red: 0, green: 16/255, blue: 26/255)
}

// MARK: - Preview

#if DEBUG
private struct KudosViewPreviewHost: View {
    @State private var lang: AppLanguage = .vi
    @State private var carouselIndex = 0
    @State private var selectedHashtag: HashtagOption? = nil
    @State private var selectedDepartment: DepartmentOption? = nil
    @State private var hashtagSheet = false
    @State private var departmentSheet = false

    var body: some View {
        KudosView(
            selectedLanguage: $lang,
            carouselIndex: $carouselIndex,
            selectedHashtag: $selectedHashtag,
            selectedDepartment: $selectedDepartment,
            isHashtagSheetPresented: $hashtagSheet,
            isDepartmentSheetPresented: $departmentSheet
        )
    }
}

#Preview {
    KudosViewPreviewHost()
        .preferredColorScheme(.dark)
}
#endif
