import SwiftUI

/// Highlight Kudos section — the full `mms_B_Highlight` block (node `6885:9084`).
///
/// Layout (top → bottom):
///   1. `KudosSectionHeader` — eyebrow + divider + gold title.
///   2. Filter row — two equal-width `KudosFilterChip`s (Hashtag / Phòng ban),
///      each 129pt wide per Figma nodes 6885:9088 / 6885:9089. The dropdown
///      panels (`KudosHashtagFilterSheet` / `KudosDepartmentFilterSheet`) are
///      anchored directly under their respective chip via `.overlay`, matching
///      Figma's startX positions (20 / 157) on the 375pt canvas.
///   3. Snap-paging carousel — 5 `KudosCard`s with iOS 17 `.scrollTransition`
///      side-fade. Side gradient hot zones (Figma 6885:9094 / 6885:9096) sit at
///      the left and right edges, half-transparent over the carousel, each
///      containing a chevron arrow that fires the prev/next callback.
///   4. `KudosCarouselDots` — "2/5" pagination with current page in gold.
struct KudosHighlightSection: View {

    // MARK: - Inputs

    let highlights: [KudosCardData]
    let selectedHashtag: HashtagOption?
    let selectedDepartment: DepartmentOption?
    let hashtagOptions: [HashtagOption]
    let departmentOptions: [DepartmentOption]
    @Binding var carouselIndex: Int
    @Binding var isHashtagSheetPresented: Bool
    @Binding var isDepartmentSheetPresented: Bool

    // MARK: - Outputs

    let onCardCopyLink: (KudosCardID) -> Void
    let onCardLike: (KudosCardID) -> Void
    let onCardViewDetail: (KudosCardID) -> Void
    let onHashtagTagTap: (String) -> Void
    let onSenderTap: (KudosCardID) -> Void
    let onRecipientTap: (KudosCardID) -> Void
    let onSelectHashtag: (HashtagOption.ID) -> Void
    let onSelectDepartment: (DepartmentOption.ID) -> Void

    // MARK: - Private state

    @State private var scrollPositionID: KudosCardID?

    // MARK: - Constants

    private let cardWidth: CGFloat        = 273
    /// Figma B.3 (node 6885:9092) frame height — locks the highlight card to
    /// 255pt so cards don't drift to ~257pt when the body block grows by a
    /// rounding pixel. The All Kudos feed uses auto height (5-line body).
    private let cardHeight: CGFloat       = 255
    private let cardSpacing: CGFloat      = 16
    /// Fallback used when the section's width is not yet known (first layout
    /// pass) — matches the Figma 375pt canvas where `(375 − 273) / 2 = 51`.
    /// At runtime `dynamicHorizontalMargin(for:)` recomputes per-device so the
    /// snapped card stays centred on wider iPhones (393pt / 430pt).
    private let horizontalMargin: CGFloat = 51
    /// Figma chips are 129pt (nodes 6885:9088 / 6885:9089), sized for the
    /// Vietnamese label "Phòng ban". The English label "Department" requires
    /// ~128pt of content alone (text 82pt + chevron 24pt + h-padding 16pt +
    /// gap 4pt), leaving no breathing room and forcing ellipsis. Widening to
    /// 145pt keeps both chips symmetric and still fits comfortably in the
    /// 375pt canvas alongside the 8pt gap and 20pt side margins.
    private let chipWidth: CGFloat        = 145
    private let sideButtonWidth: CGFloat  = 79

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerAndFilters
                // Lift the header/filter row above the carousel so the
                // dropdown overlays anchored to each chip render in front of
                // the cards rather than being shadowed by them.
                .zIndex(10)

            carouselWithDots
        }
        // Re-anchor the carousel's `scrollPositionID` whenever the highlight
        // ID set changes (filter applied, initial load, or empty→non-empty
        // toggle). The modifier MUST live on the section body — not inside
        // the carousel — because the carousel unmounts when `highlights` is
        // empty (the empty-state branch in `carouselWithDots`), and a
        // `.onChange` on an unmounted view can't catch the transition back
        // to non-empty. Without this, scrolling to card 2, filtering to BOD
        // (empty), then clearing the filter would remount the ScrollView at
        // the stale `c2.id` while the VM had already reset
        // `carouselIndex = 1` — pagination dot and visible card disagree.
        //
        // Like-toggles mutate cards in place without changing the ID set,
        // so heart taps do not fire this re-anchor.
        // iOS 16-compatible single-arg `.onChange` (the two-arg form is iOS 17+).
        // Suppressing the iOS 17 deprecation warning is fine — the section is
        // shared with the iOS 16 fallback carousel branch which also relies
        // on this re-anchor working.
        .onChange(of: highlights.map(\.id)) { newIds in
            let firstId = newIds.first
            if scrollPositionID != firstId {
                scrollPositionID = firstId
            }
        }
    }

    // MARK: - Header + filter row

    private var headerAndFilters: some View {
        VStack(alignment: .leading, spacing: 16) {
            KudosSectionHeader(
                subtitle: "kudos.section.subtitle",
                title: "kudos.section.highlight"
            )
            .padding(.horizontal, 20)

            filterRow
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Filter row (Figma 6885:9087 — HStack gap 8pt, both chips 129pt)

    private var filterRow: some View {
        HStack(alignment: .top, spacing: 8) {
            hashtagChipWithDropdown
            departmentChipWithDropdown
            Spacer(minLength: 0)
        }
        // The dropdown overlays render OUTSIDE the chip frame — disable clipping
        // so they're not cropped by the section's bounds.
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var hashtagChipWithDropdown: some View {
        KudosFilterChip(
            label: "kudos.filter.hashtag",
            identifierKey: "hashtag",
            selectedValue: selectedHashtag?.label,
            onTap: { isHashtagSheetPresented.toggle() }
        )
        .frame(width: chipWidth)
        .overlay(alignment: .topLeading) {
            if isHashtagSheetPresented {
                KudosHashtagFilterSheet(
                    items: hashtagOptions,
                    selectedId: selectedHashtag?.id,
                    onSelect: { id in
                        onSelectHashtag(id)
                        isHashtagSheetPresented = false
                    },
                    onDismiss: { isHashtagSheetPresented = false }
                )
                .offset(y: 44)         // chip height 40 + gap 4 = 44pt
                .transition(.opacity)
                .zIndex(10)
            }
        }
    }

    private var departmentChipWithDropdown: some View {
        KudosFilterChip(
            label: "kudos.filter.department",
            identifierKey: "department",
            selectedValue: selectedDepartment?.label,
            onTap: { isDepartmentSheetPresented.toggle() }
        )
        .frame(width: chipWidth)
        .overlay(alignment: .topLeading) {
            if isDepartmentSheetPresented {
                KudosDepartmentFilterSheet(
                    items: departmentOptions,
                    selectedId: selectedDepartment?.id,
                    onSelect: { id in
                        onSelectDepartment(id)
                        isDepartmentSheetPresented = false
                    },
                    onDismiss: { isDepartmentSheetPresented = false }
                )
                .offset(y: 44)
                .transition(.opacity)
                .zIndex(10)
            }
        }
    }

    // MARK: - Carousel + dots

    @ViewBuilder
    private var carouselWithDots: some View {
        if highlights.isEmpty {
            emptyState
        } else {
            VStack(spacing: 10) {
                carouselWithSideButtons
                KudosCarouselDots(
                    currentIndex: carouselIndex,
                    totalCount: max(highlights.count, 1),
                    onPrev: movePrev,
                    onNext: moveNext
                )
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Empty state (TC_IOS_KUDOS_FUN_002 — shown when filter has no
    // matches OR no Kudos exist at all). Mirrors `KudosAllSection.emptyState`
    // so both feeds carry the same visual treatment.
    private var emptyState: some View {
        Text(LocalizedStringKey("kudos.list.empty"))
            .font(.custom("Montserrat-Regular", size: 14))
            .foregroundColor(Color.white.opacity(0.6))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 32)
            .accessibilityIdentifier("kudos.highlight.emptyState")
    }

    // MARK: - Carousel + left/right edge buttons (Figma 6885:9094 / 6885:9096)

    private var carouselWithSideButtons: some View {
        GeometryReader { proxy in
            let margin = dynamicHorizontalMargin(for: proxy.size.width)
            ZStack(alignment: .center) {
                carousel(horizontalMargin: margin)
                    .frame(height: 256)
                HStack(spacing: 0) {
                    sideButton(direction: .prev)
                    Spacer()
                    sideButton(direction: .next)
                }
                .frame(height: 256)
                .allowsHitTesting(true)
            }
            .frame(width: proxy.size.width, height: 256)
        }
        .frame(height: 256)
    }

    /// Symmetric leading/trailing content margin so `viewAligned` snaps the card
    /// to the exact horizontal centre of the section regardless of device width.
    /// `(width − cardWidth) / 2` is the only value that keeps the trailing
    /// margin equal to the leading margin after the snap settles.  Clamped to
    /// `horizontalMargin` so the card never overflows the section on narrow
    /// screens (e.g. iPhone SE 320pt).
    private func dynamicHorizontalMargin(for width: CGFloat) -> CGFloat {
        guard width > 0 else { return horizontalMargin }
        return max(horizontalMargin, (width - cardWidth) / 2)
    }

    private enum CarouselSide { case prev, next }

    @ViewBuilder
    private func sideButton(direction: CarouselSide) -> some View {
        let isDisabled = direction == .prev
            ? carouselIndex <= 1
            : carouselIndex >= highlights.count

        Button {
            direction == .prev ? movePrev() : moveNext()
        } label: {
            ZStack {
                // Figma side gradient overlay — #00101A → transparent fade
                // away from the screen edge.
                LinearGradient(
                    colors: [Color.kudosSideGradient, Color.kudosSideGradient.opacity(0.5), Color.kudosSideGradient.opacity(0)],
                    startPoint: direction == .prev ? .leading : .trailing,
                    endPoint:   direction == .prev ? .trailing : .leading
                )

                Image(systemName: direction == .prev ? "chevron.left" : "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: sideButtonWidth, height: 260)
        }
        .buttonStyle(.plain)
        .opacity(isDisabled ? 0.3 : 1.0)
        .disabled(isDisabled)
        .accessibilityIdentifier("kudos.carousel.side.\(direction == .prev ? "prev" : "next")")
    }

    // MARK: - Carousel (iOS 17 snap + scrollTransition)

    /// One card cell — Figma 273×255pt frame. Shared by both iOS 17 and
    /// iOS 16 carousel branches; the iOS 17 branch overlays a
    /// `.scrollTransition` for the snap-fade effect.
    private func card(_ data: KudosCardData) -> some View {
        KudosCard(
            data: data,
            bodyLineLimit: 3,
            onCopyLink: onCardCopyLink,
            onLike: onCardLike,
            onViewDetail: onCardViewDetail,
            onHashtagTap: onHashtagTagTap,
            onSenderTap: onSenderTap,
            onRecipientTap: onRecipientTap
        )
        .frame(width: cardWidth, height: cardHeight)
    }

    @ViewBuilder
    private func carousel(horizontalMargin: CGFloat) -> some View {
        if #available(iOS 17.0, *) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: cardSpacing) {
                    ForEach(highlights) { data in
                        card(data)
                            .scrollTransition(.animated(.easeInOut(duration: 0.25))) { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1.0 : 0.88)
                                    .opacity(phase.isIdentity ? 1.0 : 0.6)
                            }
                            .id(data.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.horizontal, horizontalMargin, for: .scrollContent)
            .scrollClipDisabled()
            .scrollPosition(id: $scrollPositionID)
            .onChange(of: scrollPositionID) { _, newID in
                if let newID,
                   let idx = highlights.firstIndex(where: { $0.id == newID }) {
                    carouselIndex = idx + 1
                }
            }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: cardSpacing) {
                    ForEach(highlights, content: card)
                }
                .padding(.horizontal, horizontalMargin)
            }
        }
    }

    // MARK: - Pagination helpers

    private func movePrev() {
        guard carouselIndex > 1 else { return }
        let targetIndex = carouselIndex - 2
        guard highlights.indices.contains(targetIndex) else { return }
        if #available(iOS 17.0, *) {
            withAnimation(.easeInOut(duration: 0.25)) {
                scrollPositionID = highlights[targetIndex].id
            }
        }
        carouselIndex -= 1
    }

    private func moveNext() {
        guard carouselIndex < highlights.count else { return }
        let targetIndex = carouselIndex
        guard highlights.indices.contains(targetIndex) else { return }
        if #available(iOS 17.0, *) {
            withAnimation(.easeInOut(duration: 0.25)) {
                scrollPositionID = highlights[targetIndex].id
            }
        }
        carouselIndex += 1
    }
}

// MARK: - Color tokens

private extension Color {
    /// Figma side gradient base — #00101A.
    static let kudosSideGradient = Color(red: 0, green: 16.0 / 255, blue: 26.0 / 255)
}

// MARK: - Preview

#if DEBUG
private struct KudosHighlightPreviewHost: View {
    @State private var index = 2
    @State private var hashtagOpen = false
    @State private var deptOpen = false

    var body: some View {
        ZStack {
            Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
            ScrollView {
                KudosHighlightSection(
                    highlights: KudosCardData.mockList,
                    selectedHashtag: nil,
                    selectedDepartment: nil,
                    hashtagOptions: [HashtagOption(label: "#Dedicated"), HashtagOption(label: "#Inspring")],
                    departmentOptions: [DepartmentOption(label: "CEVC2"), DepartmentOption(label: "OPD")],
                    carouselIndex: $index,
                    isHashtagSheetPresented: $hashtagOpen,
                    isDepartmentSheetPresented: $deptOpen,
                    onCardCopyLink: { _ in },
                    onCardLike: { _ in },
                    onCardViewDetail: { _ in },
                    onHashtagTagTap: { _ in },
                    onSenderTap: { _ in },
                    onRecipientTap: { _ in },
                    onSelectHashtag: { _ in },
                    onSelectDepartment: { _ in }
                )
                .padding(.vertical, 20)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    KudosHighlightPreviewHost()
}
#endif
