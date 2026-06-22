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
    private let cardSpacing: CGFloat      = 16
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

    private var carouselWithDots: some View {
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

    // MARK: - Carousel + left/right edge buttons (Figma 6885:9094 / 6885:9096)

    private var carouselWithSideButtons: some View {
        ZStack(alignment: .center) {
            carousel
                .frame(height: 256)
            HStack(spacing: 0) {
                sideButton(direction: .prev)
                Spacer()
                sideButton(direction: .next)
            }
            .frame(height: 256)
            .allowsHitTesting(true)
        }
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

    @ViewBuilder
    private var carousel: some View {
        if #available(iOS 17.0, *) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: cardSpacing) {
                    ForEach(highlights) { card in
                        KudosCard(
                            data: card,
                            bodyLineLimit: 3,
                            onCopyLink: onCardCopyLink,
                            onLike: onCardLike,
                            onViewDetail: onCardViewDetail,
                            onHashtagTap: onHashtagTagTap,
                            onSenderTap: onSenderTap,
                            onRecipientTap: onRecipientTap
                        )
                        .frame(width: cardWidth)
                        .scrollTransition(.animated(.easeInOut(duration: 0.25))) { content, phase in
                            content
                                .scaleEffect(phase.isIdentity ? 1.0 : 0.88)
                                .opacity(phase.isIdentity ? 1.0 : 0.6)
                        }
                        .id(card.id)
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
                    ForEach(highlights) { card in
                        KudosCard(
                            data: card,
                            bodyLineLimit: 3,
                            onCopyLink: onCardCopyLink,
                            onLike: onCardLike,
                            onViewDetail: onCardViewDetail,
                            onHashtagTap: onHashtagTagTap,
                            onSenderTap: onSenderTap,
                            onRecipientTap: onRecipientTap
                        )
                        .frame(width: cardWidth)
                    }
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
