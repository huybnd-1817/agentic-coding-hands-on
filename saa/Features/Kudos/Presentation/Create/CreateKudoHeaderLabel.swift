import SwiftUI

// MARK: - CreateKudoHeaderLabel
// Figma node 6885:9292 — mms_A_Gửi lời cám ơn và ghi nhận đến đồng đội
// Montserrat Bold 14pt, #00101A, center-aligned

struct CreateKudoHeaderLabel: View {
    var body: some View {
        Text("Gửi lời cám ơn và ghi nhận đến đồng đội")
            .font(.custom("Montserrat-Bold", size: 14))
            .foregroundColor(Color.createKudoText)
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityIdentifier("createKudo.header.label")
    }
}

// MARK: - Color tokens (scoped)

extension Color {
    static let createKudoText        = Color(red: 0,        green: 16/255,   blue: 26/255)   // #00101A
    static let createKudoBorder      = Color(red: 153/255,  green: 140/255,  blue: 95/255)   // #998C5F
    static let createKudoFieldBg     = Color.white
    static let createKudoCardBg      = Color(red: 1.0,      green: 248/255,  blue: 225/255)  // #FFF8E1
    static let createKudoPlaceholder = Color(red: 153/255,  green: 153/255,  blue: 153/255)  // #999999
    static let createKudoRequired    = Color(red: 207/255,  green: 19/255,   blue: 34/255)   // #CF1322
    static let createKudoStandards   = Color(red: 228/255,  green: 96/255,   blue: 96/255)   // #E46060
    static let createKudoDeleteRed   = Color(red: 212/255,  green: 39/255,   blue: 29/255)   // #D4271D
    static let createKudoChecked     = Color(red: 153/255,  green: 140/255,  blue: 95/255)   // #998C5F
    static let createKudoGold        = Color(red: 1.0,      green: 234/255,  blue: 158/255)  // #FFEA9E
    static let createKudoCancelBg    = Color(red: 1.0,      green: 234/255,  blue: 158/255).opacity(0.10)
    static let createKudoSendBg      = Color(red: 1.0,      green: 234/255,  blue: 158/255)  // #FFEA9E solid
}

// MARK: - Preview

#if DEBUG
#Preview {
    CreateKudoHeaderLabel()
        .padding()
        .background(Color.createKudoCardBg)
}
#endif
