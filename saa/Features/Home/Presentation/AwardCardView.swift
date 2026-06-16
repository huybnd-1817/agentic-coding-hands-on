import SwiftUI

/// Single award card in the horizontally-scrollable Awards section.
/// Thumbnail area uses a solid color placeholder — real images come from
/// Supabase at integration (Track B Phase 03).
struct AwardCardView: View {

    // MARK: - Inputs

    let award: Award

    // MARK: - Outputs

    let onTap: () -> Void

    // MARK: - Environment

    // Qualified to disambiguate from the project-local `enum Environment`.
    @SwiftUI.Environment(\.locale) private var locale

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Thumbnail — async-loaded when URL present, branded placeholder otherwise.
                thumbnail
                    .frame(height: 120)

                Spacer().frame(height: 10)

                Text(award.title(for: locale))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer().frame(height: 4)

                Text(award.subtitle(for: locale))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.6))
                    .lineLimit(2)
            }
            .frame(width: 140)
            .padding(12)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.awards.card.\(award.code)")
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let url = award.thumbnailURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    placeholderThumbnail
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            placeholderThumbnail
        }
    }

    private var placeholderThumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.cardThumbnailBg)

            Image(systemName: "trophy.fill")
                .font(.system(size: 32))
                .foregroundColor(Color.homeGold.opacity(0.6))
        }
    }
}

// MARK: - Color tokens

private extension Color {
    static let cardBackground  = Color(red: 0.06, green: 0.10, blue: 0.13)
    static let cardBorder      = Color(red: 153.0/255, green: 140.0/255, blue: 95.0/255).opacity(0.35)
    static let cardThumbnailBg = Color(red: 0.10, green: 0.16, blue: 0.20)
    static let homeGold        = Color(red: 153.0/255, green: 140.0/255, blue: 95.0/255)
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        AwardCardView(
            award: HomeMockData.previewAwards[0],
            onTap: {}
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
#endif
