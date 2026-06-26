import SwiftUI

// MARK: - CreateKudoRecipientField
// Figma nodes 6885:9293/9294/9297 — B.1 label + B.2 search trigger
// Row: label (left, 93pt) + search button (right, 210pt), height 40pt, gap 8pt

struct CreateKudoRecipientField: View {

    // MARK: - Inputs

    let recipient: ProfileSummary?
    let hasError: Bool
    let onOpenPicker: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            fieldLabel
            searchButton
        }
        .frame(height: 40)
        .accessibilityIdentifier("createKudo.recipient.row")
    }

    // MARK: - Label (B.1) — "Người nhận *"

    private var fieldLabel: some View {
        HStack(spacing: 1) {
            Text("Người nhận")
                .font(.custom("Montserrat-Medium", size: 14))
                .foregroundColor(Color.createKudoText)
            Text("*")
                .font(.custom("NotoSansJP-Bold", size: 14))
                .foregroundColor(Color.createKudoRequired)
        }
        .frame(width: 93, alignment: .leading)
    }

    // MARK: - Search button (B.2)

    private var searchButton: some View {
        Button(action: onOpenPicker) {
            HStack {
                Group {
                    if let r = recipient {
                        Text(r.displayName)
                            .font(.custom("Montserrat-Regular", size: 12))
                            .foregroundColor(Color.createKudoText)
                    } else {
                        Text("Tìm kiếm")
                            .font(.custom("Montserrat-Regular", size: 12))
                            .foregroundColor(Color.createKudoPlaceholder)
                    }
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.createKudoText)
                    .frame(width: 24, height: 24)
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
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("createKudo.recipient.picker")
    }
}

// MARK: - Preview

#if DEBUG
#Preview("empty") {
    VStack(spacing: 16) {
        CreateKudoRecipientField(recipient: nil, hasError: false, onOpenPicker: {})
        CreateKudoRecipientField(
            recipient: ProfileSummary(
                id: UUID(), displayName: "Dương Huỳnh Xuân Nhật",
                employeeCode: "CECV10", avatarURL: nil, department: nil
            ),
            hasError: false,
            onOpenPicker: {}
        )
        CreateKudoRecipientField(recipient: nil, hasError: true, onOpenPicker: {})
    }
    .padding()
    .background(Color.createKudoCardBg)
}
#endif
