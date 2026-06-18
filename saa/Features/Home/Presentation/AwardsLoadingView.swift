import SwiftUI

/// Skeleton placeholder shown while awards are fetching from Supabase.
/// Three ghost cards in a horizontal row matching the loaded card dimensions.
struct AwardsLoadingView: View {

    @State private var shimmerPhase: CGFloat = 0

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    skeletonCard
                }
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
            ) {
                shimmerPhase = 1
            }
        }
    }

    private var skeletonCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 8)
                .fill(shimmerGradient)
                .frame(width: 140, height: 120)

            Spacer().frame(height: 10)

            RoundedRectangle(cornerRadius: 4)
                .fill(shimmerGradient)
                .frame(width: 100, height: 14)

            Spacer().frame(height: 4)

            RoundedRectangle(cornerRadius: 4)
                .fill(shimmerGradient)
                .frame(width: 72, height: 12)
        }
        .frame(width: 140)
        .padding(12)
        .background(Color.skeletonBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.05),
                Color.white.opacity(0.12),
                Color.white.opacity(0.05)
            ],
            startPoint: shimmerPhase == 0 ? .leading : .trailing,
            endPoint: shimmerPhase == 0 ? .trailing : .leading
        )
    }
}

// MARK: - Color tokens

private extension Color {
    static let skeletonBg = Color(red: 0.06, green: 0.10, blue: 0.13)
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        AwardsLoadingView()
    }
    .preferredColorScheme(.dark)
}
#endif
