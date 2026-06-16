import SwiftUI

/// Kudos promotional banner section. Conditionally rendered based on
/// `isKudosAvailable` feature flag (clarification 2026-06-15: local constant,
/// migrated to remote config later). Only shown when the flag is true.
struct HomeKudosSection: View {

    // MARK: - Outputs

    let onKudosDetail: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader

            bannerCard
        }
    }

    // MARK: - Header

    private var sectionHeader: some View {
        Text(LocalizedStringKey("home.kudos.sectionTitle"))
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
    }

    // MARK: - Banner card

    private var bannerCard: some View {
        Button(action: onKudosDetail) {
            ZStack(alignment: .bottomLeading) {
                // Placeholder background — real image at integration
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.kudosBannerStart,
                                Color.kudosBannerEnd
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 140)

                // Decorative trophy icon (SF placeholder)
                Image(systemName: "hands.clap.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color.white.opacity(0.12))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .padding(.trailing, 20)

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey("home.kudos.eyebrow"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    Text(LocalizedStringKey("home.kudos.body"))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.75))
                }
                .padding(16)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.kudosBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.kudos.details")
        .padding(.horizontal, 20)
    }
}

// MARK: - Color tokens

private extension Color {
    static let kudosBannerStart = Color(red: 0.08, green: 0.18, blue: 0.28)
    static let kudosBannerEnd   = Color(red: 0.04, green: 0.10, blue: 0.16)
    static let kudosBorder      = Color(red: 153.0/255, green: 140.0/255, blue: 95.0/255).opacity(0.4)
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        HomeKudosSection(onKudosDetail: {})
            .padding(.vertical, 20)
    }
    .preferredColorScheme(.dark)
}
#endif
