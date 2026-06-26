import SwiftUI

// MARK: - HashtagDropdown

/// Hashtag selection dropdown panel for the Create Kudos flow
/// (MoMorph screen `aKWA2klsnt`, node `6891:17706` — "Dropdown list hashtag").
///
/// ## Design spec (Figma `6891:17706`)
/// Container: width 311 pt, padding 6 pt, border-radius 8 pt, background `#00070C`,
/// border `1px solid #998C5F`.
///
/// The panel is **presentational only** — it owns no selection state. The parent
/// (CreateKudosViewModel) passes all state down and receives mutation callbacks.
///
/// ## Integration contract
/// ```swift
/// HashtagDropdown(
///     hashtags: vm.availableHashtags,          // [Hashtag]
///     selectedIds: vm.selectedHashtagIds,       // Set<HashtagID>
///     isAtMax: vm.isAtMaxHashtags,             // Bool
///     onToggleHashtag: { vm.toggleHashtag($0) },
///     onDismiss: { vm.closeHashtagDropdown() }
/// )
/// ```
///
/// Place the panel inside an `.overlay(alignment: .topLeading)` or
/// `ZStack` at the call site. This view does NOT provide backdrop dimming —
/// the caller owns that layer.
@MainActor
struct HashtagDropdown: View {

    // MARK: - Inputs

    /// Full list of available hashtags, ordered as returned by the repository.
    let hashtags: [Hashtag]
    /// IDs of currently selected hashtags.
    let selectedIds: Set<HashtagID>
    /// When `true`, unselected rows are dimmed and non-interactive.
    /// Derived from: `selectedIds.count >= maxHashtags` (max 5, enforced by VM).
    let isAtMax: Bool

    // MARK: - Outputs

    /// Fires when a row is tapped — passes the affected `Hashtag`.
    /// Caller decides whether to select or deselect based on `selectedIds`.
    let onToggleHashtag: (Hashtag) -> Void
    /// Fires when the dropdown should be dismissed (tap-outside handled by caller).
    let onDismiss: () -> Void

    // MARK: - Body

    // Figma rows are 40pt tall; cap visible at 8 → 320pt. Scroll when hashtags > 8.
    private static let rowHeight: CGFloat = 40
    private static let maxVisibleRows = 8

    var body: some View {
        // Shrink list height to fit when hashtags < maxVisibleRows; scroll otherwise.
        let visibleRows = min(hashtags.count, Self.maxVisibleRows)
        let listHeight = Self.rowHeight * CGFloat(visibleRows)

        ScrollView(.vertical, showsIndicators: hashtags.count > Self.maxVisibleRows) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(hashtags) { hashtag in
                    let isSelected = selectedIds.contains(hashtag.id)
                    HashtagDropdownRow(
                        hashtag: hashtag,
                        isSelected: isSelected,
                        isDisabled: isAtMax && !isSelected,
                        onToggle: { onToggleHashtag(hashtag) }
                    )
                }
            }
        }
        .frame(height: listHeight)
        // Figma container: padding 6pt wrapping all rows.
        .padding(6)
        // Width determined by parent overlay padding (32pt from screen edge each side).
        .frame(maxWidth: .infinity)
        // Figma background: Details-Container-2 #00070C.
        .background(Color.hashtagDropdownBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        // Figma border: 1px solid Details-Border #998C5F.
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.hashtagDropdownBorder, lineWidth: 1)
        )
        // Elevation for overlay legibility (not explicitly in Figma but
        // expected for floating panels on dark backgrounds).
        .shadow(color: .black.opacity(0.30), radius: 8, x: 0, y: 4)
        .accessibilityIdentifier("kudos.createHashtag.dropdown")
    }
}

// MARK: - Color tokens (file-private)

private extension Color {
    /// Figma `Details-Container-2` — #00070C.
    static let hashtagDropdownBackground = Color(
        red: 0,
        green: 7.0 / 255,
        blue: 12.0 / 255
    )
    /// Figma `Details-Border` — #998C5F.
    static let hashtagDropdownBorder = Color(
        red: 153.0 / 255,
        green: 140.0 / 255,
        blue: 95.0 / 255
    )
}

// MARK: - Preview

#if DEBUG
/// Verbatim Figma hashtag labels from MoMorph screen `aKWA2klsnt` node `6891:17706`.
/// Runtime data comes from `fetchHashtags()` seed; these labels are for visual validation only.
private let figmaHashtags: [Hashtag] = [
    Hashtag(id: UUID(uuidString: "f1000001-0000-0000-0000-000000000001")!, tag: "#High-performing"),
    Hashtag(id: UUID(uuidString: "f1000001-0000-0000-0000-000000000002")!, tag: "#BE PROFESSIONAL"),
    Hashtag(id: UUID(uuidString: "f1000001-0000-0000-0000-000000000003")!, tag: "#BE OPTIMISTIC"),
    Hashtag(id: UUID(uuidString: "f1000001-0000-0000-0000-000000000004")!, tag: "#BE A TEAM"),
    Hashtag(id: UUID(uuidString: "f1000001-0000-0000-0000-000000000005")!, tag: "#THINK OUTSIDE THE BOX"),
    Hashtag(id: UUID(uuidString: "f1000001-0000-0000-0000-000000000006")!, tag: "#GET RISKY"),
    Hashtag(id: UUID(uuidString: "f1000001-0000-0000-0000-000000000007")!, tag: "#GO FAST"),
    Hashtag(id: UUID(uuidString: "f1000001-0000-0000-0000-000000000008")!, tag: "#WASSHOI")
]

#Preview("HashtagDropdown — 3 selected (matches Figma A state)") {
    // Figma shows rows 1, 2, 3 selected; rows 4–8 unselected.
    let selectedIds: Set<HashtagID> = [
        figmaHashtags[0].id,
        figmaHashtags[1].id,
        figmaHashtags[2].id
    ]
    return ZStack {
        Color(red: 0, green: 16.0 / 255, blue: 26.0 / 255).ignoresSafeArea()
        HashtagDropdown(
            hashtags: figmaHashtags,
            selectedIds: selectedIds,
            isAtMax: false,
            onToggleHashtag: { _ in },
            onDismiss: {}
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("HashtagDropdown — isAtMax (5 selected, unselected rows disabled)") {
    let selectedIds: Set<HashtagID> = Set(figmaHashtags.prefix(5).map(\.id))
    return ZStack {
        Color(red: 0, green: 16.0 / 255, blue: 26.0 / 255).ignoresSafeArea()
        HashtagDropdown(
            hashtags: figmaHashtags,
            selectedIds: selectedIds,
            isAtMax: true,
            onToggleHashtag: { _ in },
            onDismiss: {}
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("HashtagDropdown — empty selection") {
    return ZStack {
        Color(red: 0, green: 16.0 / 255, blue: 26.0 / 255).ignoresSafeArea()
        HashtagDropdown(
            hashtags: figmaHashtags,
            selectedIds: [],
            isAtMax: false,
            onToggleHashtag: { _ in },
            onDismiss: {}
        )
    }
    .preferredColorScheme(.dark)
}
#endif
