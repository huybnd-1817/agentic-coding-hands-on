import SwiftUI

/// Top 10 gift recipients list (MoMorph `mms_D.3_10 SUNNER nhận quà` — id `6885:9255`).
///
/// Renders a dark-background rounded card with:
///   - Section title "10 SUNNER NHẬN QUÀ MỚI NHẤT" in gold (D.3.1)
///   - Vertical list of recipient rows: circular avatar + name (bold gold) + reward label (white)
///
/// When `recipients` is empty, shows a Vietnamese "Chưa có dữ liệu" placeholder.
///
/// Design values (Figma node 6885:9255):
/// - Background: #00070C, border: 0.794pt solid #998C5F, corner radius: 8pt, padding: 12pt
/// - Title: Montserrat Bold 14pt, #FFEA9E, centered
/// - Row gap: 6.35pt, row height: 38pt
/// - Avatar: 32×32pt circle, border: 1.483pt solid #FFFFFF
/// - Name: Montserrat Bold 14pt, #FFEA9E, left-aligned
/// - Reward label: Montserrat Regular 12pt, #FFFFFF, left-aligned
/// - Avatar-to-text gap: 6.35pt
@MainActor
struct KudosTopRecipientsSection: View {

    // MARK: - Inputs

    let recipients: [KudosRecipientData]
    let onRecipientTap: (KudosRecipientID) -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            sectionTitle

            if recipients.isEmpty {
                emptyState
            } else {
                recipientsList
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.recipientsCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.recipientsCardBorder, lineWidth: 0.794)
        )
    }

    // MARK: - Section title (D.3.1)

    private var sectionTitle: some View {
        Text(LocalizedStringKey("kudos.recipients.title"))
            .font(.custom("Montserrat-Bold", size: 14))
            .foregroundColor(.recipientsTitle)
            .frame(maxWidth: .infinity, alignment: .center)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .accessibilityIdentifier("kudos.topRecipients.title")
    }

    // MARK: - Recipients list

    private var recipientsList: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(recipients) { recipient in
                recipientRow(recipient)
            }
        }
    }

    // MARK: - Single recipient row (D.3.2)

    private func recipientRow(_ recipient: KudosRecipientData) -> some View {
        Button {
            onRecipientTap(recipient.id)
        } label: {
            HStack(alignment: .center, spacing: 6) {
                // Circular avatar with white border
                Image(recipient.avatarAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.recipientsAvatarBorder, lineWidth: 1.483)
                    )
                    .accessibilityHidden(true)

                // Name + reward label column
                VStack(alignment: .leading, spacing: 2) {
                    Text(recipient.name)
                        .font(.custom("Montserrat-Bold", size: 14))
                        .foregroundColor(.recipientsName)
                        .lineLimit(1)

                    Text(recipient.rewardLabel)
                        .font(.custom("Montserrat-Regular", size: 12))
                        .foregroundColor(.recipientsReward)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 38)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipient.name), \(recipient.rewardLabel)")
    }

    // MARK: - Empty state

    private var emptyState: some View {
        Text(LocalizedStringKey("kudos.recipients.empty"))
            .font(.custom("Montserrat-Regular", size: 14))
            .foregroundColor(.recipientsReward)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 12)
            .accessibilityIdentifier("kudos.topRecipients.empty")
    }
}

// MARK: - Color tokens

private extension Color {
    /// Figma `Details-Container-2` — #00070C.
    static let recipientsCardBackground = Color(red: 0, green: 7.0/255, blue: 12.0/255)
    /// Figma `Details-Border` — #998C5F.
    static let recipientsCardBorder     = Color(red: 153.0/255, green: 140.0/255, blue: 95.0/255)
    /// Figma title — rgba(255,234,158,1) / gold.
    static let recipientsTitle          = Color(red: 1.0, green: 234.0/255, blue: 158.0/255)
    /// Figma name text — rgba(255,234,158,1) / gold.
    static let recipientsName           = Color(red: 1.0, green: 234.0/255, blue: 158.0/255)
    /// Figma reward label — rgba(255,255,255,1) / white.
    static let recipientsReward         = Color.white
    /// Figma avatar border — #FFFFFF.
    static let recipientsAvatarBorder   = Color.white
}

// MARK: - Preview

#if DEBUG
#Preview("Populated") {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        KudosTopRecipientsSection(
            recipients: KudosRecipientData.mockList,
            onRecipientTap: { _ in }
        )
        .padding(.horizontal, 20)
    }
    .preferredColorScheme(.dark)
}

#Preview("Empty") {
    ZStack {
        Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
        KudosTopRecipientsSection(
            recipients: [],
            onRecipientTap: { _ in }
        )
        .padding(.horizontal, 20)
    }
    .preferredColorScheme(.dark)
}
#endif
