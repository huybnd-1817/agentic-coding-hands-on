import SwiftUI

/// Shared section header used by Awards (mms_4.1_header) and Kudos
/// (mms_5.1_header). Renders an eyebrow line, a 1px divider, and a gold
/// section title — matching the Figma `Home Section Header` component.
struct HomeSectionHeader: View {

    let eyebrowKey: LocalizedStringKey
    let titleKey: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrowKey)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white)

            Rectangle()
                .fill(Color.sectionHeaderDivider)
                .frame(maxWidth: .infinity)
                .frame(height: 1)

            Text(titleKey)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.sectionHeaderTitle)
                .padding(.top, 4)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Color tokens

private extension Color {
    /// Figma section divider — #2E3940.
    static let sectionHeaderDivider = Color(red: 46.0/255, green: 57.0/255, blue: 64.0/255)
    /// Figma `Details-Text-Primary-1` — #FFEA9E (gold title).
    static let sectionHeaderTitle   = Color(red: 1.0, green: 234.0/255, blue: 158.0/255)
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        VStack(spacing: 32) {
            HomeSectionHeader(
                eyebrowKey: "home.awards.eventLabel",
                titleKey: "home.awards.sectionTitle"
            )
            HomeSectionHeader(
                eyebrowKey: "home.kudos.eyebrow",
                titleKey: "home.kudos.sectionTitle"
            )
        }
        .padding(.vertical, 20)
    }
    .preferredColorScheme(.dark)
}
#endif
