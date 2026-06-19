import SwiftUI

/// Send Kudos button (MoMorph `mms_A.1_Button ghi nhận` — id `6885:9083`).
///
/// A tappable card-style row with a pen/edit icon on the left and placeholder
/// text on the right. Acts as the entry point for composing a new Kudos.
///
/// Design values (Figma node 6885:9083):
/// - Width: 335pt, Height: 40pt (padding 10pt on all sides)
/// - Background: rgba(255,234,158, 0.10) — translucent gold tint
/// - Border: 1pt solid #998C5F, corner radius: 4pt
/// - Icon (I6885:9083;28:2013): `kudos-send-pen-icon`, 24×24pt
/// - Label (I6885:9083;28:2014): Montserrat Medium 14pt, white (#FFFFFF),
///   lineHeight 20pt, text "Hôm nay, bạn muốn gửi kudos đến ai?"
struct KudosSendButton: View {

    // MARK: - Outputs

    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image("kudos-send-pen-icon")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)

                Text(LocalizedStringKey("kudos.send.placeholder"))
                    .font(.custom("Montserrat-Medium", size: 14))
                    .foregroundColor(.kudosSendLabel)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 10)
            .frame(height: 40)
            .frame(maxWidth: .infinity)
            .background(Color.kudosSendBackground)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.kudosSendBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(LocalizedStringKey("kudos.send.placeholder"))
        .accessibilityIdentifier("kudos.sendButton")
    }
}

// MARK: - Color tokens

private extension Color {
    /// Figma button fill — rgba(255,234,158, 0.10).
    static let kudosSendBackground = Color(red: 1.0, green: 234.0/255, blue: 158.0/255).opacity(0.10)
    /// Figma `Colors-Boder` — #998C5F.
    static let kudosSendBorder     = Color(red: 153.0/255, green: 140.0/255, blue: 95.0/255)
    /// Figma label color — #FFFFFF.
    static let kudosSendLabel      = Color.white
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        KudosSendButton(onTap: {})
            .padding(.horizontal, 20)
    }
    .preferredColorScheme(.dark)
}
#endif
