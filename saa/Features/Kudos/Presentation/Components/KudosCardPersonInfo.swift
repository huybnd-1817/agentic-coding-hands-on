import SwiftUI

/// Person info cell used inside `KudosCard`'s `trao nhận` row.
///
/// Matches Figma component `6885:8347` (Infor): avatar circle (24×24pt, white
/// 0.865pt border), display name (10pt Regular, dark), employee code + star
/// badge side by side (10pt Medium code · 2pt dot · `KudosStarBadge`).
///
/// The view is purely presentational — tap gesture is applied by `KudosCard`.
struct KudosCardPersonInfo: View {

    // MARK: - Inputs

    let name: String
    let code: String
    let starTier: StarTier
    /// Remote avatar URL. When non-nil rendered via `AsyncImage`; otherwise
    /// falls back to a standard SF Symbol (`person.crop.circle.fill`).
    let avatarURL: URL?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            avatarView
            metaView
        }
        .frame(width: 109)
        .contentShape(Rectangle())
    }

    // MARK: - Avatar

    /// Renders the avatar from `avatarURL` via `AsyncImage` when available,
    /// falling back to a standard `person.crop.circle.fill` SF Symbol while
    /// loading or on failure. Sizing/clipping/border match Figma B.3.1 / B.3.5
    /// (24×24pt circle, white 0.865pt border).
    @ViewBuilder
    private var avatarView: some View {
        Group {
            if let url = avatarURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .empty, .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
        .frame(width: 24, height: 24)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(Color.white, lineWidth: 0.865)
        )
    }

    /// Standard SF Symbol fallback used when no remote avatar is available
    /// (per `--quick` directive 2026-06-23). Tinted to the card's sub-text
    /// grey so it reads as a neutral placeholder rather than competing with
    /// the gold/cream card palette.
    private var placeholderImage: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.kudosPersonSubtext)
    }

    // MARK: - Name + code + star badge row

    private var metaView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.custom("Montserrat-Regular", size: 10))
                .foregroundColor(Color.kudosPersonText)
                .lineLimit(1)

            HStack(spacing: 4) {
                Text(code)
                    .font(.custom("Montserrat-Medium", size: 10))
                    .foregroundColor(Color.kudosPersonSubtext)
                    .lineLimit(1)

                if starTier != .zero {
                    Circle()
                        .fill(Color.kudosPersonSubtext.opacity(0.4))
                        .frame(width: 2, height: 2)

                    KudosStarBadge(tier: starTier)
                }
            }
        }
    }
}

// MARK: - Star badge

/// Bordered pill rendering 1–3 gold ★ icons per `StarTier` (B.3.6).
///
/// Callers MUST guard against `.zero` and skip rendering — the badge has no
/// "zero stars" visual state. Borders + corner radius mirror the legacy
/// role-badge geometry (Figma `6885:8331`, 0.231pt gold, 22.217pt radius)
/// so layout neighbours don't reflow when the badge appears.
struct KudosStarBadge: View {

    let tier: StarTier

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0 ..< max(tier.rawValue, 1), id: \.self) { _ in
                Image(systemName: "star.fill")
                    .font(.system(size: 6, weight: .medium))
                    .foregroundColor(Color.kudosGoldPrimary)
            }
        }
        .padding(.horizontal, 3)
        .frame(height: 9)
        .overlay(
            RoundedRectangle(cornerRadius: 22.217)
                .stroke(Color.kudosGoldPrimary, lineWidth: 0.231)
        )
        .accessibilityLabel(accessibilityKey)
    }

    /// Localized label per tier. `.zero` falls back to the `.one` key because
    /// the badge should never be instantiated with `.zero` — the parent
    /// already hides it. The fallback exists only to keep the property
    /// total without forcing every caller to handle an optional.
    private var accessibilityKey: LocalizedStringKey {
        switch tier {
        case .zero, .one: return "kudos.starTier.one"
        case .two:        return "kudos.starTier.two"
        case .three:      return "kudos.starTier.three"
        }
    }
}

// MARK: - Color tokens

private extension Color {
    /// Primary text on cream card — #00101A.
    static let kudosPersonText    = Color(red: 0.0,       green: 16.0/255, blue: 26.0/255)
    /// Code / sub-text — rgba(153,153,153,1).
    static let kudosPersonSubtext = Color(red: 153.0/255, green: 153.0/255, blue: 153.0/255)
    /// Figma `Colors-Primary` / border gold — #FFEA9E.
    static let kudosGoldPrimary   = Color(red: 1.0,       green: 234.0/255, blue: 158.0/255)
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        HStack(spacing: 16) {
            KudosCardPersonInfo(
                name: "Huỳnh Dương Xuân...",
                code: "CECV10",
                starTier: .one,
                avatarURL: nil
            )
            KudosCardPersonInfo(
                name: "Dương Xuân Huỳnh...",
                code: "CECV10",
                starTier: .three,
                avatarURL: nil
            )
        }
        .padding(20)
    }
    .preferredColorScheme(.dark)
}
#endif
