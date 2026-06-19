import SwiftUI

/// Person info cell used inside `KudosCard`'s `trao nhận` row.
///
/// Matches Figma component `6885:8347` (Infor): avatar circle (24×24pt, white
/// 0.865pt border), display name (10pt Regular, dark), employee code + role
/// badge side by side (10pt Medium code · 2pt dot · bordered role pill).
///
/// The view is purely presentational — tap gesture is applied by `KudosCard`.
struct KudosCardPersonInfo: View {

    // MARK: - Inputs

    let name: String
    let code: String
    let role: String
    let avatarAssetName: String

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

    private var avatarView: some View {
        Image(avatarAssetName)
            .resizable()
            .scaledToFill()
            .frame(width: 24, height: 24)
            .clipShape(Circle())
            .overlay(
                Circle().stroke(Color.white, lineWidth: 0.865)
            )
    }

    // MARK: - Name + code + badge row

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

                Circle()
                    .fill(Color.kudosPersonSubtext.opacity(0.4))
                    .frame(width: 2, height: 2)

                KudosRoleBadge(roleText: role)
            }
        }
    }
}

// MARK: - Role badge

/// Bordered pill label for sender/recipient hero tier (e.g. "Rising Hero").
/// Figma component `6885:8331` — 0.231pt gold border, 22.217pt corner radius.
struct KudosRoleBadge: View {

    let roleText: String

    var body: some View {
        Text(roleText)
            .font(.custom("Montserrat-Regular", size: 7))
            .foregroundColor(Color.kudosGoldPrimary)
            .lineLimit(1)
            .padding(.horizontal, 3)
            .frame(height: 9)
            .overlay(
                RoundedRectangle(cornerRadius: 22.217)
                    .stroke(Color.kudosGoldPrimary, lineWidth: 0.231)
            )
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
                role: "Rising Hero",
                avatarAssetName: "kudos-card-avatar-male"
            )
            KudosCardPersonInfo(
                name: "Dương Xuân Huỳnh...",
                code: "CECV10",
                role: "Legend Hero",
                avatarAssetName: "kudos-card-avatar-recipient"
            )
        }
        .padding(20)
    }
    .preferredColorScheme(.dark)
}
#endif
