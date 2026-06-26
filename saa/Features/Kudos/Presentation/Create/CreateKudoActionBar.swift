import SwiftUI

// MARK: - CreateKudoActionBar
// Figma node 6891:16832 — H Cancel + I Send buttons
// Layout: HStack(spacing: 16), height 40pt, full width
// Cancel (6891:16833): flex-1, border 1pt #998C5F, bg rgba(FFEA9E, 0.10), radius 4pt
// Send   (6891:16834): fixed 160pt, bg #FFEA9E solid, radius 4pt
// Both: Montserrat-Medium 14pt; Cancel white text, Send #00101A text

struct CreateKudoActionBar: View {

    // MARK: - Inputs

    let isSubmitting: Bool
    let onCancel: () -> Void
    let onSubmit: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 16) {
            cancelButton
            sendButton
        }
        .frame(height: 40)
        .accessibilityIdentifier("createKudo.actionBar")
    }

    // MARK: - Cancel button (H)
    // Figma 6885:10003: Label "Huỷ" + mm_media_icon (24x24, white)

    private var cancelButton: some View {
        Button(action: onCancel) {
            HStack(spacing: 8) {
                Text("Huỷ")
                    .font(.custom("Montserrat-Medium", size: 14))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.createKudoCancelBg)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.createKudoBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .disabled(isSubmitting)
        .opacity(isSubmitting ? 0.6 : 1.0)
        .accessibilityIdentifier("createKudo.action.cancel")
    }

    // MARK: - Send button (I)
    // Figma 6885:10004: Label "Gửi đi" + mm_media_icon (24x24).
    // Icon asset: kudos-card-direction-arrow (existing SVG, #00101A fill).

    private var sendButton: some View {
        Button(action: onSubmit) {
            HStack(spacing: 8) {
                Text("Gửi đi")
                    .font(.custom("Montserrat-Medium", size: 14))
                    .foregroundColor(Color.createKudoText)
                    .lineLimit(1)

                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color.createKudoText)
                        .frame(width: 24, height: 24)
                } else {
                    Image("kudos-card-direction-arrow")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Color.createKudoText)
                        .frame(width: 24, height: 24)
                }
            }
            .frame(width: 160, height: 40)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.createKudoSendBg)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .disabled(isSubmitting)
        .opacity(isSubmitting ? 0.7 : 1.0)
        .accessibilityIdentifier("createKudo.action.submit")
    }
}

// MARK: - Preview

#if DEBUG
#Preview("idle") {
    CreateKudoActionBar(isSubmitting: false, onCancel: {}, onSubmit: {})
        .padding()
        .background(Color.createKudoCardBg)
}

#Preview("submitting") {
    CreateKudoActionBar(isSubmitting: true, onCancel: {}, onSubmit: {})
        .padding()
        .background(Color.createKudoCardBg)
}
#endif
