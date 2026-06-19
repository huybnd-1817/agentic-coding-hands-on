import SwiftUI

/// Dropdown filter chip used in the Highlight and All Kudos sections.
///
/// Matches Figma component `6885:8322` (node `6885:9088` / `6885:9089`):
///   - Border: 1pt solid #998C5F, corner radius 4pt.
///   - Background: rgba(255, 234, 158, 0.10) — faint gold tint.
///   - Height: 40pt, inner padding 8pt.
///   - Left: placeholder or selected-value label (14pt Montserrat Regular, white).
///   - Right: 24×24pt chevron-down icon (`kudos-carousel-arrow` rotated
///     90° is NOT used here — chip uses a system chevron for simplicity since
///     the Figma IC node is a generic icon slot).
///
/// Two visual states:
///   - **Placeholder**: shows `label` in full opacity white.
///   - **Selected**: shows `selectedValue` in gold (#FFEA9E) to signal active filter.
///
/// The chip itself is a tap target only. Sheet presentation is owned by the
/// parent section; this component fires `onTap` and stays purely presentational.
struct KudosFilterChip: View {

    // MARK: - Inputs

    /// Placeholder text shown when no value is selected (e.g. "Hashtag").
    let label: String
    /// Currently selected filter value, or `nil` when no filter is active.
    let selectedValue: String?
    /// Called when the user taps the chip.
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(displayText)
                    .font(.custom("Montserrat-Regular", size: 14))
                    .foregroundColor(isSelected ? .kudosFilterSelected : .white)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Figma chevron `mm_media_IC` (I6885:9088;89:2249) — cropped at
                // 24×24pt from the rendered frame. Template-rendered so colour
                // tints with selection state.
                Image("kudos-filter-chevron")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundColor(isSelected ? .kudosFilterSelected : .white)
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 8)
            .frame(height: 40)
            .background(Color.kudosFilterBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.kudosFilterBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSelected ? "\(label): \(selectedValue ?? "")" : label)
        .accessibilityHint("Double tap to open filter")
        .accessibilityIdentifier("kudos.filterChip.\(label)")
    }

    // MARK: - Helpers

    private var isSelected: Bool { selectedValue != nil }
    private var displayText: String { selectedValue ?? label }
}

// MARK: - Color tokens

private extension Color {
    /// Figma `Details-Border` — #998C5F.
    static let kudosFilterBorder     = Color(red: 153.0/255, green: 140.0/255, blue: 95.0/255)
    /// Figma `Details-SecondaryButton-Normal` — rgba(255,234,158,0.10).
    static let kudosFilterBackground = Color(red: 1.0, green: 234.0/255, blue: 158.0/255).opacity(0.10)
    /// Gold accent when a value is selected — #FFEA9E.
    static let kudosFilterSelected   = Color(red: 1.0, green: 234.0/255, blue: 158.0/255)
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                KudosFilterChip(label: "Hashtag",   selectedValue: nil,          onTap: {})
                    .frame(width: 129)
                KudosFilterChip(label: "Phòng ban", selectedValue: nil,          onTap: {})
                    .frame(width: 129)
            }
            HStack(spacing: 8) {
                KudosFilterChip(label: "Hashtag",   selectedValue: "Dedicated",  onTap: {})
                    .frame(width: 129)
                KudosFilterChip(label: "Phòng ban", selectedValue: "Engineering",onTap: {})
                    .frame(width: 129)
            }
        }
        .padding(.horizontal, 20)
    }
    .preferredColorScheme(.dark)
}
#endif
