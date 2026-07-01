import SwiftUI

// MARK: - AwardDropdownRow

/// A single row inside the award selector dropdown panel.
///
/// Visual states (mirrors HashtagDropdownRow pattern):
/// - **Selected**: `rgba(255, 234, 158, 0.20)` tinted background, corner 2pt,
///   white text, gold checkmark trailing icon.
/// - **Unselected**: transparent background, white text, no icon.
///
/// Row is 40pt tall with 12pt horizontal padding.
/// Text: system 14pt Regular.
struct AwardDropdownRow: View {

    // MARK: - Inputs

    let title: String
    let isSelected: Bool

    // MARK: - Outputs

    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.awardRowGold)
                        .frame(width: 24, height: 24)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(isSelected ? Color.awardRowGold.opacity(0.20) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: isSelected ? 2 : 0))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Color tokens (file-private)

private extension Color {
    /// Figma gold palette `#FFEA9E` — base for checkmark fill (solid) and
    /// selected-row background (applied with `.opacity(0.20)`).
    static let awardRowGold = Color(red: 1.0, green: 234.0/255, blue: 158.0/255)
}

// MARK: - Preview

#if DEBUG
#Preview("AwardDropdownRow states") {
    ZStack {
        Color(red: 0, green: 7.0/255, blue: 12.0/255).ignoresSafeArea()
        VStack(spacing: 0) {
            AwardDropdownRow(title: "Top Talent", isSelected: true, onTap: {})
            AwardDropdownRow(title: "Top Project", isSelected: false, onTap: {})
            AwardDropdownRow(title: "Top Project Leader", isSelected: false, onTap: {})
            AwardDropdownRow(title: "Best Manager", isSelected: false, onTap: {})
            AwardDropdownRow(title: "Signature 2025 - Creator", isSelected: false, onTap: {})
            AwardDropdownRow(title: "MVP", isSelected: false, onTap: {})
        }
        .frame(width: 280)
    }
    .preferredColorScheme(.dark)
}
#endif
