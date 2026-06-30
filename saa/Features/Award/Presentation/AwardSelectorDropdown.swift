import SwiftUI

// MARK: - AwardSelectorDropdown

/// Custom panel dropdown chip for switching the selected `Award`.
///
/// Matches Figma `mms_B_Highlight / filter / dropdown` (id `6885:10287`):
/// - Chip: gold-bordered rounded rect, height 40pt, gold-tinted 10% fill.
/// - Shows `award.title(for: locale)` + chevron-down icon.
/// - On tap: reveals a floating panel beneath the chip (HashtagDropdown pattern).
///
/// Panel styling (matches `HashtagDropdown`):
/// - Background: `#00070C` (`Details-Container-2`).
/// - Border: 1pt solid `#998C5F` (`Details-Border`).
/// - Corner radius: 8pt. Padding: 6pt. Shadow: black 30%, radius 8, y 4.
///
/// Figma chip values:
/// - Border: 1pt solid #998C5F (`Details-Border`).
/// - Background: rgba(255, 234, 158, 0.10) (`Details-SecondaryButton-Normal`).
/// - Corner radius: 4pt. Padding: 8pt.
/// - Label: Montserrat Regular 14pt, #FFFFFF, letterSpacing 0.25pt.
struct AwardSelectorDropdown: View {

    // MARK: - Inputs

    let awards: [Award]
    let selected: Award

    // MARK: - Outputs

    let onSelect: (Award) -> Void

    // MARK: - Environment

    @SwiftUI.Environment(\.locale) private var locale

    // MARK: - State

    @State private var isOpen: Bool = false

    // MARK: - Body

    var body: some View {
        chip
            .accessibilityIdentifier("award.detail.selector")
            .overlay(alignment: .topLeading) {
                if isOpen {
                    panel
                        .offset(y: 44) // pin top of panel to bottom of chip
                }
            }
            .zIndex(isOpen ? 10 : 0)
    }

    // MARK: - Chip

    private var chip: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                isOpen.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Text(selected.title(for: locale))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isOpen ? 180 : 0))
                    .animation(.easeInOut(duration: 0.18), value: isOpen)
            }
            .padding(.horizontal, 12)
            .frame(minWidth: 140, idealHeight: 40, maxHeight: 40)
            .background(Color.selectorChipFill)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.selectorChipBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Dropdown panel

    private var panel: some View {
        let rowHeight: CGFloat = 40
        let visibleRows = min(awards.count, 8)
        let listHeight = rowHeight * CGFloat(visibleRows)

        return ScrollView(.vertical, showsIndicators: awards.count > 8) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(awards) { award in
                    AwardDropdownRow(
                        title: award.title(for: locale),
                        isSelected: award.id == selected.id,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                isOpen = false
                            }
                            onSelect(award)
                        }
                    )
                    .accessibilityIdentifier("award.detail.selector.option.\(award.code)")
                }
            }
        }
        .frame(height: listHeight)
        .padding(6)
        .frame(maxWidth: .infinity)
        .background(Color.selectorPanelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.selectorChipBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.30), radius: 8, x: 0, y: 4)
        .accessibilityIdentifier("award.detail.selector.panel")
    }
}

// MARK: - Color tokens

private extension Color {
    /// Figma `Details-Border` — #998C5F.
    static let selectorChipBorder = Color(red: 153.0/255, green: 140.0/255, blue: 95.0/255)
    /// Figma `Details-SecondaryButton-Normal` — rgba(255, 234, 158, 0.10).
    static let selectorChipFill   = Color(red: 1.0, green: 234.0/255, blue: 158.0/255).opacity(0.10)
    /// Figma `Details-Container-2` — #00070C.
    static let selectorPanelBackground = Color(red: 0, green: 7.0/255, blue: 12.0/255)
}

// MARK: - Preview

#if DEBUG
private struct AwardSelectorDropdownPreviewHost: View {
    @State private var selected = HomeMockData.previewAwards[0]

    var body: some View {
        ZStack {
            Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
            VStack {
                AwardSelectorDropdown(
                    awards: HomeMockData.previewAwards,
                    selected: selected,
                    onSelect: { selected = $0 }
                )
                .frame(width: 160)
                .padding()
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    AwardSelectorDropdownPreviewHost()
}
#endif
