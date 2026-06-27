import SwiftUI

// MARK: - HashtagDropdownRow

/// A single row inside the hashtag selection dropdown (MoMorph screen `aKWA2klsnt`).
///
/// ## Visual states (from Figma node `6891:17706`)
/// - **Selected** (`mms_A_Hashtag đã chọn 1/2/3`): `rgba(255, 234, 158, 0.20)` tinted background,
///   `border-radius: 2px`, white text, checkmark trailing icon (A.2 `mms_A.2_icon đã chọn`).
/// - **Unselected** (`Hashtag chưa chọn`): transparent background, white text, no icon.
/// - **Disabled** (`isAtMax && !isSelected`): same layout as unselected, `opacity: 0.38` per
///   Material-equivalent disabled token — touch blocked.
///
/// The row is 40 pt tall with 16 pt horizontal padding. Text uses `Montserrat-Medium 500, 14/20`.
@MainActor
struct HashtagDropdownRow: View {

    // MARK: - Inputs

    let hashtag: Hashtag
    let isSelected: Bool
    /// When `true` and the row is NOT selected, the row is dimmed and non-interactive.
    let isDisabled: Bool

    // MARK: - Outputs

    let onToggle: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .center, spacing: 2) {
                // A.1 — Hashtag label
                Text(hashtag.tag)
                    .font(.custom("Montserrat-Medium", size: 14))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .tracking(0.1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // A.2 — Checkmark icon (only when selected).
                // Figma component `1002:13201` from set `178:1020`.
                // Renders as a filled circle-checkmark in the Figma gold palette (#FFEA9E).
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.hashtagCheckmarkColor)
                        .frame(width: 24, height: 24)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
                isSelected
                    ? Color.hashtagRowSelectedBackground
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: isSelected ? 2 : 0))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.38 : 1.0)
        .accessibilityIdentifier("kudos.createHashtag.row.\(hashtag.tag)")
        .accessibilityLabel(
            isSelected
                ? "\(hashtag.tag), selected"
                : hashtag.tag
        )
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Color tokens (file-private)

private extension Color {
    /// Figma: `rgba(255, 234, 158, 0.20)` — selected row background.
    static let hashtagRowSelectedBackground = Color(
        red: 255.0 / 255,
        green: 234.0 / 255,
        blue: 158.0 / 255
    ).opacity(0.20)

    /// Figma: gold palette `#FFEA9E` — A.2 checkmark circle fill color.
    static let hashtagCheckmarkColor = Color(
        red: 255.0 / 255,
        green: 234.0 / 255,
        blue: 158.0 / 255
    )
}

// MARK: - Preview

#if DEBUG
#Preview("HashtagDropdownRow states") {
    let figmaHashtags: [Hashtag] = [
        Hashtag(id: UUID(), tag: "#High-performing"),
        Hashtag(id: UUID(), tag: "#BE PROFESSIONAL"),
        Hashtag(id: UUID(), tag: "#BE OPTIMISTIC"),
        Hashtag(id: UUID(), tag: "#BE A TEAM"),
        Hashtag(id: UUID(), tag: "#THINK OUTSIDE THE BOX")
    ]
    let selectedId = figmaHashtags[2].id

    return ZStack {
        Color(red: 0, green: 7.0 / 255, blue: 12.0 / 255).ignoresSafeArea()
        VStack(spacing: 0) {
            ForEach(figmaHashtags) { hashtag in
                HashtagDropdownRow(
                    hashtag: hashtag,
                    isSelected: hashtag.id == selectedId,
                    isDisabled: false,
                    onToggle: {}
                )
            }
        }
        .frame(width: 311)
    }
    .preferredColorScheme(.dark)
}

#Preview("HashtagDropdownRow — isAtMax disabled") {
    let figmaHashtags: [Hashtag] = [
        Hashtag(id: UUID(), tag: "#High-performing"),
        Hashtag(id: UUID(), tag: "#BE PROFESSIONAL"),
        Hashtag(id: UUID(), tag: "#BE OPTIMISTIC")
    ]
    let selectedId = figmaHashtags[0].id

    return ZStack {
        Color(red: 0, green: 7.0 / 255, blue: 12.0 / 255).ignoresSafeArea()
        VStack(spacing: 0) {
            ForEach(figmaHashtags) { hashtag in
                HashtagDropdownRow(
                    hashtag: hashtag,
                    isSelected: hashtag.id == selectedId,
                    isDisabled: hashtag.id != selectedId,
                    onToggle: {}
                )
            }
        }
        .frame(width: 311)
    }
    .preferredColorScheme(.dark)
}
#endif
