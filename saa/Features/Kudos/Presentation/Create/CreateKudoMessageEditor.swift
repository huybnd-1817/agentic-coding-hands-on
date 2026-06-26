import SwiftUI

// MARK: - CreateKudoMessageEditor
// Figma nodes 6885:9304/9305/9306/9322/9323
// Layout (column, gap 1.787pt):
//   C row — MarkdownToolbar (height 24pt)
//   D text area — white bordered textarea (min 89.362pt)
//   D.1 hint — grey 10pt text below

struct CreateKudoMessageEditor: View {

    // MARK: - Inputs

    @Binding var message: String
    let hasError: Bool
    let onApplyMarkdown: (MarkdownMarker) -> Void
    let onTapStandards: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 1.787) {
            editorBlock
            hintText
        }
        .accessibilityIdentifier("createKudo.message.editor")
    }

    // MARK: - Editor block (toolbar + textarea joined)

    private var editorBlock: some View {
        VStack(spacing: 0) {
            // C — Markdown toolbar
            MarkdownToolbar(
                onApplyMarkdown: onApplyMarkdown,
                onTapStandards: onTapStandards
            )

            // D — Text area (Figma 6885:9322: border, white bg, min-height 89.362pt)
            ZStack(alignment: .topLeading) {
                if message.isEmpty {
                    Text("Hãy gửi gắm lời cám ơn và ghi nhận đến đồng \nđội tại đây nhé! ")
                        .font(.custom("Montserrat-Regular", size: 12))
                        .foregroundColor(Color.createKudoPlaceholder)
                        .lineSpacing(4)
                        .padding(8)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $message)
                    .font(.custom("Montserrat-Regular", size: 12))
                    .foregroundColor(Color.createKudoText)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(4)
                    .accessibilityIdentifier("createKudo.message.textEditor")
            }
            .frame(minHeight: 89.362)
            .background(Color.createKudoFieldBg)
            .overlay(
                // Only bottom + sides border (top edge shared with toolbar overlay)
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 3.574,
                    bottomTrailingRadius: 3.574,
                    topTrailingRadius: 0
                )
                .stroke(hasError ? Color.createKudoRequired : Color.createKudoBorder, lineWidth: 0.447)
            )
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 3.574,
                    bottomTrailingRadius: 3.574,
                    topTrailingRadius: 0
                )
            )
        }
    }

    // MARK: - D.1 hint — Figma 6885:9323

    private var hintText: some View {
        Text("Bạn có thể \"@ + tên\" để nhắc tới đồng nghiệp khác")
            .font(.custom("Montserrat-Regular", size: 10))
            .foregroundColor(Color.createKudoPlaceholder)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("createKudo.message.hint")
    }
}

// MARK: - Preview

#if DEBUG
private struct MessageEditorPreviewHost: View {
    @State private var message = ""
    @State private var filled = "Cảm ơn người em bình thường nhưng phi thường :D Cảm ơn sự chăm chỉ, cần mẫn của em đã tạo động lực rất lớn cho mọi người trong team."

    var body: some View {
        VStack(spacing: 20) {
            CreateKudoMessageEditor(
                message: $message,
                hasError: false,
                onApplyMarkdown: { _ in },
                onTapStandards: {}
            )

            CreateKudoMessageEditor(
                message: $filled,
                hasError: false,
                onApplyMarkdown: { _ in },
                onTapStandards: {}
            )
        }
        .padding()
        .background(Color.createKudoCardBg)
    }
}

#Preview {
    MessageEditorPreviewHost()
}
#endif
