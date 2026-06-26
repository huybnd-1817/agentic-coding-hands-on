import SwiftUI

// MARK: - CreateKudoTitleField
// Figma nodes 6885:9298/9299/9302/9303 — B.1 "Danh hiệu *" label + B.2 text input

struct CreateKudoTitleField: View {

    // MARK: - Inputs

    @Binding var title: String
    let hasError: Bool
    let onTitleChange: (String) -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                fieldLabel
                titleInput
            }
            .frame(minHeight: 40)
        }
        .accessibilityIdentifier("createKudo.title.row")
    }

    // MARK: - Label (B.1) — "Danh hiệu *"
    // Figma 6885:9911: label-frame width 84pt natural. Set to 93pt to align
    // input start with recipient row (recipient label is 93pt wide).

    private var fieldLabel: some View {
        HStack(spacing: 1) {
            Text("Danh hiệu")
                .font(.custom("Montserrat-Medium", size: 14))
                .foregroundColor(Color.createKudoText)
            Text("*")
                .font(.custom("NotoSansJP-Bold", size: 14))
                .foregroundColor(Color.createKudoRequired)
        }
        .frame(width: 93, alignment: .leading)
    }

    // MARK: - Title text input (B.2)
    // Placeholder "Dành tặng một danh hiệu cho..." Montserrat 400 12pt #999999.
    // Left-aligned per UX requirement (overrides figma textAlign:center).

    private var titleInput: some View {
        ZStack(alignment: .leading) {
            if title.isEmpty {
                Text("Dành tặng một danh hiệu cho...")
                    .font(.custom("Montserrat-Regular", size: 12))
                    .foregroundColor(Color.createKudoPlaceholder)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .allowsHitTesting(false)
            }

            TextField("", text: $title)
                .font(.custom("Montserrat-Regular", size: 12))
                .foregroundColor(Color.createKudoText)
                .tint(Color.createKudoText)
                .multilineTextAlignment(.leading)
                .onChange(of: title) { onTitleChange($0) }
        }
        .padding(.horizontal, 10.723)
        .padding(.vertical, 7.149)
        .frame(maxWidth: .infinity, minHeight: 40)
        .background(Color.createKudoFieldBg)
        .overlay(
            RoundedRectangle(cornerRadius: 3.574)
                .stroke(hasError ? Color.createKudoRequired : Color.createKudoBorder, lineWidth: 0.447)
        )
        .clipShape(RoundedRectangle(cornerRadius: 3.574))
        .accessibilityIdentifier("createKudo.title.input")
    }
}

// MARK: - CreateKudoStandardsLink
// Figma node 6885:9303 — B.5 hint text + "Tiêu chuẩn cộng đồng" tappable link
// Figma node 6885:9319 — the red "Tiêu chuẩn cộng đồng" button is inside the toolbar row.
// This component renders only the two-line grey hint below the award row.

struct CreateKudoStandardsLink: View {

    let onTapStandards: () -> Void

    var body: some View {
        // Figma 6885:9303 — fontSize 12, color #999999, lineHeight 16px, two lines
        // The "Tiêu chuẩn cộng đồng" link is rendered inside MarkdownToolbar (C row).
        // This label carries only the hint copy.
        Text("Ví dụ: Người truyền động lực cho tôi.\nDanh hiệu sẽ hiển thị làm tiêu đề Kudos của bạn.")
            .font(.custom("Montserrat-Regular", size: 12))
            .foregroundColor(Color.createKudoPlaceholder)
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("createKudo.title.hint")
    }
}

// MARK: - Preview

#if DEBUG
private struct TitleFieldPreviewHost: View {
    @State private var title1 = ""
    @State private var title2 = "Người truyền động lực cho tôi"
    @State private var title3 = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CreateKudoTitleField(title: $title1, hasError: false, onTitleChange: { _ in })
            CreateKudoTitleField(title: $title2, hasError: false, onTitleChange: { _ in })
            CreateKudoTitleField(title: $title3, hasError: true, onTitleChange: { _ in })
            CreateKudoStandardsLink(onTapStandards: {})
        }
        .padding()
        .background(Color.createKudoCardBg)
    }
}

#Preview {
    TitleFieldPreviewHost()
}
#endif
