import SwiftUI

/// Theme paragraph that sits between the hero block and the awards list
/// (MoMorph node `mms_3_note` — id `6885:9028`). Pure text body, localized
/// via `home.theme.body`.
struct HomeNoteSection: View {

    var body: some View {
        Text(LocalizedStringKey("home.theme.body"))
            .font(.system(size: 13, weight: .light))
            .foregroundColor(Color.white.opacity(0.85))
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        HomeNoteSection()
            .padding(.vertical, 20)
    }
    .preferredColorScheme(.dark)
}
#endif
