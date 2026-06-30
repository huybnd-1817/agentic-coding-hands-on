import SwiftUI

/// Person info cell inside `KudosCard`'s `trao nhận` row (Figma `6885:8347`).
/// Pure presentation — tap gesture is applied by `KudosCard`.
struct KudosCardPersonInfo: View {

    // MARK: - Inputs

    let name: String
    let code: String
    let starTier: StarTier
    /// nil → SF Symbol placeholder.
    let avatarURL: URL?
    /// Replaces the `code + star` row (used by anonymous-sender layout).
    var subtitle: LocalizedStringKey? = nil

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

    /// `AsyncImage` when `avatarURL` is set; SF Symbol fallback otherwise.
    @ViewBuilder
    private var avatarView: some View {
        Group {
            if let url = avatarURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
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

    /// Sub-text grey so it reads neutral against the gold/cream palette.
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

            if let subtitle {
                Text(subtitle)
                    .font(.custom("Montserrat-Regular", size: 10))
                    .foregroundColor(Color.kudosPersonSubtext)
                    .lineLimit(1)
            } else {
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
}

// MARK: - Star badge

/// Bordered pill rendering 1–3 gold ★ icons per `StarTier` (Figma B.3.6).
/// Callers MUST skip `.zero` — there is no zero-stars visual state.
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

    /// `.zero` falls back to `.one` — the badge is never instantiated with
    /// `.zero` (parent already hides it); fallback keeps the property total.
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
