import SwiftUI

/// Open Secret Box CTA button (MoMorph `Button` — id `6885:9254` inside `mms_D.1`).
///
/// Yellow rounded button matching the design:
/// - Background: #FFEA9E (gold/cream), corner radius: 4pt
/// - Label: Montserrat Medium 14pt, #00101A (dark), text "Mở Secret Box"
/// - Gift icon: SF Symbol `gift.fill`, 24×24pt, dark tinted
/// - Disabled state: greyed out (opacity 0.4) per clarification TC_FUN_039
///
/// Design values (Figma node 6885:9254):
/// - Width: 312pt (full card width), height: 40pt, padding: 12pt horizontal
/// - Gap between icon and label: 8pt
/// - Background: rgba(255,234,158,1), border-radius: 4pt
@MainActor
struct KudosSecretBoxButton: View {

    // MARK: - Inputs

    let isEnabled: Bool
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "gift.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.secretBoxIconColor)

                Text(LocalizedStringKey("kudos.secretBox.open"))
                    .font(.custom("Montserrat-Medium", size: 14))
                    .foregroundColor(.secretBoxLabelColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .padding(.horizontal, 12)
            .background(Color.secretBoxBackground)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        // Greyed out when disabled — TC_FUN_039: box button inactive when no boxes available.
        .opacity(isEnabled ? 1.0 : 0.4)
        .accessibilityLabel(LocalizedStringKey("kudos.secretBox.open"))
        .accessibilityHint(isEnabled ? "" : "Không có Secret Box để mở")
        .accessibilityIdentifier("kudos.secretBoxButton")
    }
}

// MARK: - Color tokens

private extension Color {
    /// Figma button background — rgba(255,234,158,1) / #FFEA9E.
    static let secretBoxBackground = Color(red: 1.0, green: 234.0/255, blue: 158.0/255)
    /// Figma button label — rgba(0,16,26,1) / #00101A.
    static let secretBoxLabelColor = Color(red: 0, green: 16.0/255, blue: 26.0/255)
    /// Gift icon uses same dark tint as label.
    static let secretBoxIconColor  = Color(red: 0, green: 16.0/255, blue: 26.0/255)
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        VStack(spacing: 16) {
            KudosSecretBoxButton(isEnabled: true, onTap: {})
            KudosSecretBoxButton(isEnabled: false, onTap: {})
        }
        .padding(.horizontal, 20)
    }
    .preferredColorScheme(.dark)
}
#endif
