import SwiftUI

// MARK: - MarkdownToolbar
// Figma nodes 6885:9306/9307..9319 — C row: 6 icon buttons + "Tiêu chuẩn cộng đồng" link
// Layout: HStack flush-right, each icon button 24x24pt with 4pt padding = 32pt hit area
// Border 0.447pt #998C5F on every cell; first cell has top-left radius 3.574, last top-right

struct MarkdownToolbar: View {

    // MARK: - Outputs

    let onApplyMarkdown: (MarkdownMarker) -> Void
    let onTapStandards: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            toolbarButton(marker: .bold, iconName: "bold", isFirst: true)
            toolbarButton(marker: .italic, iconName: "italic")
            toolbarButton(marker: .strikethrough, iconName: "strikethrough")
            toolbarButton(marker: .orderedList, iconName: "list.number")
            toolbarButton(marker: .link, iconName: "link")
            toolbarButton(marker: .quote, iconName: "text.quote")
            standardsButton
        }
        .frame(height: 24)
        .accessibilityIdentifier("createKudo.markdown.toolbar")
    }

    // MARK: - Individual icon button

    private func toolbarButton(
        marker: MarkdownMarker,
        iconName: String,
        isFirst: Bool = false
    ) -> some View {
        Button {
            onApplyMarkdown(marker)
        } label: {
            Image(systemName: iconName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.createKudoText)
                .frame(width: 16, height: 16)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.clear)
        .overlay(
            Rectangle()
                .stroke(Color.createKudoBorder, lineWidth: 0.447)
        )
        // Clip first button with top-left radius only (matches Figma border-radius: 3.574px 0 0 0).
        // Subsequent buttons are plain rectangles so the row reads as one continuous bar.
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: isFirst ? 3.574 : 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0
            )
        )
        .accessibilityIdentifier("createKudo.markdown.\(marker.rawValue)")
    }

    // MARK: - "Tiêu chuẩn cộng đồng" button (Figma 6885:9319)
    // flex: 1, border same, top-right radius 3.574, text color #E46060, fontSize 10

    private var standardsButton: some View {
        Button(action: onTapStandards) {
            Text("Tiêu chuẩn cộng đồng")
                .font(.custom("Montserrat-Regular", size: 10))
                .foregroundColor(Color.createKudoStandards)
                .underline(true, color: Color.createKudoStandards)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.clear)
        .overlay(
            Rectangle()
                .stroke(Color.createKudoBorder, lineWidth: 0.447)
        )
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 3.574
            )
        )
        .accessibilityIdentifier("createKudo.standards.link")
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    MarkdownToolbar(onApplyMarkdown: { _ in }, onTapStandards: {})
        .padding()
        .background(Color.createKudoCardBg)
}
#endif
