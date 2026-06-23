import SwiftUI

/// Department filter dropdown panel (MoMorph `mms_A_Dropdown-CEV` — id `6891:21234`).
///
/// Self-contained card intended to be placed in a `.overlay(alignment: .topLeading)`
/// or `.popover` by the caller. No backdrop dimming — the caller owns that layer.
///
/// Verbatim department labels from MoMorph node 6891:21234:
///   Row 1 (selected style): CEVC2
///   Row 2: CEVC3
///   Row 3: CEVC4
///   Row 4: CEVC1
///   Row 5: OPD
///   Row 6: Infra
///
/// Selection: selected row uses white background + dark text (inverted).
/// Default row: dark navy background + white text.
/// Re-tapping the selected id clears it — the view simply emits the id;
/// clearing logic lives in the caller.
@MainActor
struct KudosDepartmentFilterSheet: View {

    // MARK: - Inputs

    let items: [DepartmentOption]
    let selectedId: DepartmentOption.ID?

    // MARK: - Outputs

    let onSelect: (DepartmentOption.ID) -> Void
    let onDismiss: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(items) { item in
                rowView(for: item)
            }
        }
        // Figma panel container: width 129px, padding 6px, border-radius 8px,
        // background #00070C, border 1px #998C5F.
        .padding(6)
        .frame(width: 129)
        .background(Color.deptDropdownBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.deptDropdownBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    }

    // MARK: - Row

    @ViewBuilder
    private func rowView(for item: DepartmentOption) -> some View {
        let isSelected = item.id == selectedId

        Button {
            onSelect(item.id)
        } label: {
            HStack {
                Text(item.label)
                    // Figma: Montserrat 700 (selected) / 500 (default), 14pt.
                    .font(.custom(
                        isSelected ? "Montserrat-Bold" : "Montserrat-Medium",
                        size: 14
                    ))
                    // Figma color is #FFFFFF on BOTH states — glow + weight differentiate.
                    .foregroundColor(.white)
                    .shadow(color: isSelected ? .black.opacity(0.25) : .clear, radius: 4, x: 0, y: 4)
                    .shadow(color: isSelected ? .deptRowSelectedGlow : .clear, radius: 6, x: 0, y: 0)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .frame(height: 40)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.deptRowSelectedBackground : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("kudos.deptFilter.row.\(item.label)")
    }
}

// MARK: - Color tokens

private extension Color {
    /// Figma panel background — `Details-Container-2` #00070C.
    static let deptDropdownBackground       = Color(red: 0, green: 7.0 / 255, blue: 12.0 / 255)
    /// Figma border — `Details-Border` #998C5F.
    static let deptDropdownBorder           = Color(red: 153.0 / 255, green: 140.0 / 255, blue: 95.0 / 255)
    /// Selected row background — Figma rgba(255, 234, 158, 0.10).
    static let deptRowSelectedBackground    = Color(red: 1.0, green: 234.0 / 255, blue: 158.0 / 255).opacity(0.10)
    /// Selected row gold glow — Figma `text-shadow: 0 0 6px #FAE287`.
    static let deptRowSelectedGlow          = Color(red: 250.0 / 255, green: 226.0 / 255, blue: 135.0 / 255)
}

// MARK: - Preview

#if DEBUG
#Preview {
    // Verbatim labels from MoMorph node 6891:21234.
    let items: [DepartmentOption] = [
        DepartmentOption(label: "CEVC2"),
        DepartmentOption(label: "CEVC3"),
        DepartmentOption(label: "CEVC4"),
        DepartmentOption(label: "CEVC1"),
        DepartmentOption(label: "OPD"),
        DepartmentOption(label: "Infra")
    ]
    return ZStack {
        Color(red: 0, green: 16.0 / 255, blue: 26.0 / 255).ignoresSafeArea()
        KudosDepartmentFilterSheet(
            items: items,
            selectedId: items.first?.id,
            onSelect: { _ in },
            onDismiss: {}
        )
    }
    .preferredColorScheme(.dark)
}
#endif
