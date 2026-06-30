import SwiftUI

// MARK: - Color tokens (file-private)

private extension Color {
    static let profileScreenBg = Color(red: 0,         green: 16.0/255,  blue: 26.0/255)  // #00101A
    static let profileCardBg   = Color(red: 1.0,       green: 248.0/255, blue: 225.0/255) // #FFF8E1
    static let profileGold     = Color(red: 1.0,       green: 234.0/255, blue: 158.0/255) // #FFEA9E
    static let profileText     = Color(red: 0,         green: 16.0/255,  blue: 26.0/255)  // #00101A
    static let profileSubtext  = Color(red: 153.0/255, green: 153.0/255, blue: 153.0/255) // #999999
}

// MARK: - KudosAuthorProfileStubView

/// Placeholder pushed on sender/recipient tap from the detail screen.
/// Renders the in-memory `KudosAuthor` — no fetch / use-case / repository.
/// Hook point for the real profile feature.
@MainActor
struct KudosAuthorProfileStubView: View {

    // MARK: - Inputs

    let author: KudosAuthor
    let onBack: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            screenBackground
            VStack(spacing: 0) {
                navigationBar
                ScrollView {
                    profileCard
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                        .padding(.bottom, 24)
                }
                // Identifier on ScrollView (not outer ZStack) so SwiftUI's
                // identifier-propagation does NOT shadow `kudos.detail.profile.back`.
                // Mirrors the fix applied to ViewKudoDetailView.
                .accessibilityIdentifier("kudos.detail.profile.root")
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Background

    private var screenBackground: some View {
        Color.profileScreenBg.ignoresSafeArea()
    }

    // MARK: - Custom nav bar (mirrors ViewKudoDetailView header style)

    private var navigationBar: some View {
        ZStack {
            Color.clear.ignoresSafeArea(edges: .top)
            VStack(spacing: 0) {
                Color.clear.frame(height: 47)
                HStack(spacing: 0) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .frame(width: 42, height: 42)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 7)
                    .accessibilityIdentifier("kudos.detail.profile.back")
                    Spacer()
                    Text(LocalizedStringKey("kudos.detail.profile.title"))
                        .font(.custom("Helvetica Neue", size: 17).weight(.medium))
                        .foregroundColor(.white)
                        .tracking(0.5)
                    Spacer()
                    Color.clear.frame(width: 42, height: 42).padding(.trailing, 7)
                }
                .frame(height: 42)
            }
        }
        .frame(height: 89)
    }

    // MARK: - Profile card

    private var profileCard: some View {
        VStack(spacing: 16) {
            avatar
            nameAndCode
            if starTier != .zero {
                KudosStarBadge(tier: starTier)
            }
            comingSoonFooter
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color.profileCardBg)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.profileGold, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var avatar: some View {
        Group {
            if let url = author.avatarURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        placeholderAvatar
                    }
                }
            } else {
                placeholderAvatar
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.profileGold, lineWidth: 2))
    }

    private var placeholderAvatar: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.profileSubtext)
    }

    private var nameAndCode: some View {
        VStack(spacing: 4) {
            Text(author.displayName)
                .font(.custom("Montserrat-Bold", size: 16))
                .foregroundColor(Color.profileText)
                .multilineTextAlignment(.center)
            if let code = author.employeeCode, !code.isEmpty {
                Text(code)
                    .font(.custom("Montserrat-Medium", size: 12))
                    .foregroundColor(Color.profileSubtext)
            }
        }
    }

    private var comingSoonFooter: some View {
        Text(LocalizedStringKey("kudos.detail.profile.comingSoon"))
            .font(.custom("Montserrat-Regular", size: 11))
            .foregroundColor(Color.profileSubtext)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
    }

    // MARK: - Derived

    private var starTier: StarTier {
        StarTier.from(received: author.kudosReceivedCount)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Profile stub") {
    KudosAuthorProfileStubView(
        author: KudosAuthor(
            userId: UUID(),
            displayName: "Huỳnh Dương Xuân Phong",
            employeeCode: "CECV10",
            avatarURL: nil,
            departmentId: nil,
            kudosReceivedCount: 42
        ),
        onBack: {}
    )
    .preferredColorScheme(.dark)
}
#endif
