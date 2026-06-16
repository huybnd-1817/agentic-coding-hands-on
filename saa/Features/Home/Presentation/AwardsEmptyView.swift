import SwiftUI

/// Shown when the awards list loads successfully but contains zero items.
struct AwardsEmptyView: View {

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy")
                .font(.system(size: 36))
                .foregroundColor(Color.white.opacity(0.3))

            Text(LocalizedStringKey("home.awards.empty"))
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        AwardsEmptyView()
    }
    .preferredColorScheme(.dark)
}
#endif
