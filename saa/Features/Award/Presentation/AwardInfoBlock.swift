import SwiftUI

// MARK: - AwardInfoBlock

/// Badge image + title + description + quantity + prize row(s).
///
/// Matches Figma `mms_2.3_award` (id `6885:10292`):
/// - Badge: 160×160pt, gold border 0.455pt #FFEA9E, corner 11.429pt, gold-glow shadow.
/// - Title row: 24pt tall, icon 24pt + bold gold 14pt text.
/// - Description: Montserrat Light 14pt, white, lineHeight 20pt, letterSpacing 0.25pt.
/// - Divider: 1pt, #2E3940.
/// - Quantity row: diamond icon + bold gold label + 18pt bold white value + 14pt light unit.
/// - Prize row(s): flag icon + bold gold label + 18pt bold white value + 14pt light note.
///   Dual-prize (Signature): two consecutive prize rows, no separator between them.
struct AwardInfoBlock: View {

    // MARK: - Inputs

    let award: Award

    // MARK: - Environment

    @SwiftUI.Environment(\.locale) private var locale

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            badgeImage
                .frame(maxWidth: .infinity, alignment: .center)

            titleRow
            descriptionText

            divider
            quantityRow

            divider
            prizeRows
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Badge (160×160)

    private var badgeImage: some View {
        let hasAsset = UIImage(named: "award-badge-\(award.code)") != nil
        return AwardBadgeAssetRegistry.image(for: award.code)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 160, height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 11.429))
            .overlay(
                RoundedRectangle(cornerRadius: 11.429)
                    .stroke(Color.infoGold, lineWidth: 0.455)
            )
            .shadow(color: Color.infoGlow.opacity(0.55), radius: 3, x: 0, y: 0)
            .shadow(color: Color.black.opacity(0.25), radius: 1.9, x: 0, y: 1.9)
            .accessibilityIdentifier(hasAsset ? "award.badge.\(award.code)" : "award.badge.placeholder")
            .accessibilityLabel(
                hasAsset
                    ? award.title(for: locale)
                    : NSLocalizedString("award.detail.placeholder.badgeMissing", comment: "")
            )
    }

    // MARK: - Title row

    private var titleRow: some View {
        HStack(spacing: 8) {
            icon("award-icon-title")
            Text(award.title(for: locale))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.infoGold)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Description

    private var descriptionText: some View {
        Text(award.subtitle(for: locale))
            .font(.system(size: 14, weight: .light))
            .foregroundColor(.white)
            .lineSpacing(6)
            .tracking(0.25)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(Color.infoDivider)
            .frame(maxWidth: .infinity)
            .frame(height: 1)
    }

    // MARK: - Quantity row

    private var quantityRow: some View {
        infoSection(iconName: "award-icon-quantity", labelKey: "award.detail.quantityLabel") {
            valueRow(value: String(format: "%02d", award.quantity), note: Text(award.quantityUnit))
        }
    }

    // MARK: - Prize rows (single or dual)

    @ViewBuilder
    private var prizeRows: some View {
        if let teamValue = award.prizeValueTeam {
            // Dual prize: individual + team
            prizeRow(value: award.prizeValueIndividual, noteKey: "award.detail.prizeNote.individual")
            prizeRow(value: teamValue, noteKey: "award.detail.prizeNote.team")
        } else {
            prizeRow(value: award.prizeValueIndividual, noteKey: resolvedSinglePrizeNoteKey)
        }
    }

    /// Picks the appropriate note key for single-prize awards based on `award.prizeNote`.
    private var resolvedSinglePrizeNoteKey: String {
        switch award.prizeNote {
        case "cho giải cá nhân": return "award.detail.prizeNote.individual"
        case "cho giải tập thể": return "award.detail.prizeNote.team"
        default:                 return "award.detail.prizeNote.eachAward"
        }
    }

    private func prizeRow(value: String, noteKey: String) -> some View {
        infoSection(iconName: "award-icon-prize", labelKey: "award.detail.prizeLabel") {
            valueRow(value: value, note: Text(LocalizedStringKey(noteKey)))
        }
    }

    // MARK: - Shared row builders

    /// 24×24 leading icon used by every labelled section.
    private func icon(_ name: String) -> some View {
        Image(name)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 24)
    }

    /// Section with a `[icon + bold gold label]` header above arbitrary content.
    /// Used for both quantity and prize rows.
    private func infoSection<Content: View>(
        iconName: String,
        labelKey: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                icon(iconName)
                Text(LocalizedStringKey(labelKey))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.infoGold)
            }
            content()
        }
    }

    /// `[18pt bold white value]  [14pt light white note]` — shared by quantity + prize rows.
    private func valueRow(value: String, note: Text) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .tracking(0.5)
                .foregroundColor(.white)

            note
                .font(.system(size: 14, weight: .light))
                .tracking(0.25)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Color tokens

private extension Color {
    /// Figma `Details-Text-Primary-1` — #FFEA9E.
    static let infoGold    = Color(red: 1.0,       green: 234.0/255, blue: 158.0/255)
    /// Figma box-shadow gold halo — #FAE287.
    static let infoGlow    = Color(red: 250.0/255, green: 226.0/255, blue: 135.0/255)
    /// Figma section divider — #2E3940.
    static let infoDivider = Color(red: 46.0/255,  green: 57.0/255,  blue: 64.0/255)
}

// MARK: - Preview

#if DEBUG
private struct AwardInfoBlockPreviewHost: View {
    let award: Award
    var body: some View {
        ZStack {
            Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
            ScrollView {
                AwardInfoBlock(award: award).padding(.vertical, 20)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview("Single prize — Top Talent") {
    AwardInfoBlockPreviewHost(award: HomeMockData.previewAwards[0])
}

#Preview("Dual prize — Signature") {
    AwardInfoBlockPreviewHost(award: HomeMockData.previewAwards[4])
}
#endif
