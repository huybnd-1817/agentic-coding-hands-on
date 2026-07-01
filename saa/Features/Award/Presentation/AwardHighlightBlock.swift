import SwiftUI

// MARK: - AwardHighlightBlock

/// Eyebrow + title header + award-selector dropdown chip.
///
/// Matches Figma `mms_B_Highlight` (id `6885:10283`):
/// - Outer VStack gap 16pt, 335×137pt.
/// - Header instance (id `6885:10285`): eyebrow 12pt Regular white,
///   1pt divider #2E3940, gold title 22pt Medium.
/// - Filter chip row (id `6885:10286`): height 40pt.
struct AwardHighlightBlock: View {

    // MARK: - Inputs

    let award: Award
    let awards: [Award]

    // MARK: - Outputs

    let onSelect: (Award) -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HomeSectionHeader(
                eyebrowKey: "award.detail.eyebrow",
                titleKey: "award.detail.title"
            )

            HStack {
                AwardSelectorDropdown(
                    awards: awards,
                    selected: award,
                    onSelect: onSelect
                )
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Preview

#if DEBUG
private struct AwardHighlightBlockPreviewHost: View {
    @State private var selected = HomeMockData.previewAwards[0]

    var body: some View {
        ZStack {
            Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
            AwardHighlightBlock(
                award: selected,
                awards: HomeMockData.previewAwards,
                onSelect: { selected = $0 }
            )
            .padding(.vertical, 20)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    AwardHighlightBlockPreviewHost()
}
#endif
