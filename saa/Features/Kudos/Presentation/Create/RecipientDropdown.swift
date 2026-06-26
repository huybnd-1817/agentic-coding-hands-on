import SwiftUI

/// Recipient search dropdown panel — Figma `mms_B_Dropdown-List` (node `6891:17450`).
///
/// Appears as an overlay panel anchored below the recipient text input when the
/// user starts typing. Hosts a search field at the top, then a scrollable list
/// of `RecipientRow` items (or `RecipientEmptyState` when there are no matches),
/// and a dismiss-on-outside-tap gesture via `onDismiss`.
///
/// Panel geometry (from Figma):
///   - width 311pt, border 1pt #998C5F (Details-Border gold), corner radius 8pt
///   - background #00070C (Details-Container-2)
///   - inner padding 6pt on all sides
///   - rows are 60pt tall with no gap between them (B.1 and B.3 are contiguous)
///
/// Integration contract (props + callbacks from VM — phase-07 wires real data):
///   - `query: String`              — current search text (controlled)
///   - `results: [ProfileSummary]`  — pre-filtered list from VM
///   - `isLoading: Bool`            — shows skeleton/spinner while VM loads
///   - `onQueryChange(String)`      — fired on every keystroke
///   - `onSelectRecipient(ProfileSummary)` — fired when user taps a row
///   - `onDismiss`                  — fired when tapping outside the panel
@MainActor
struct RecipientDropdown: View {

    // MARK: - Inputs

    let query: String
    let results: [ProfileSummary]
    let isLoading: Bool

    // MARK: - Callbacks

    let onQueryChange: (String) -> Void
    let onSelectRecipient: (ProfileSummary) -> Void
    let onDismiss: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            searchField
            Divider()
                .background(Color(red: 153.0/255, green: 140.0/255, blue: 95.0/255))
                .padding(.vertical, 4)
            resultsList
        }
        .padding(6)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0, green: 7.0/255, blue: 12.0/255))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 153.0/255, green: 140.0/255, blue: 95.0/255), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityIdentifier("kudos.create.recipientDropdown")
    }

    // MARK: - Search field

    /// Matches Figma `search` instance (node `6891:17231`): white background,
    /// 1pt #998C5F border, corner radius 3.574pt, 10.723pt H / 7.149pt V padding,
    /// Montserrat Regular 12pt text in #00101A, search icon trailing (24×24pt).
    private var searchField: some View {
        HStack(spacing: 4) {
            TextField("", text: Binding(
                get: { query },
                set: { onQueryChange($0) }
            ))
            .font(.custom("Montserrat-Regular", size: 12))
            .foregroundColor(Color(red: 0, green: 16.0/255, blue: 26.0/255))
            .tint(Color(red: 0, green: 16.0/255, blue: 26.0/255))
            .accessibilityIdentifier("kudos.create.recipientSearchField")

            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(red: 0, green: 16.0/255, blue: 26.0/255))
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 10.723)
        .padding(.vertical, 7.149)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 3.574)
                .stroke(Color(red: 153.0/255, green: 140.0/255, blue: 95.0/255), lineWidth: 0.447)
        )
        .clipShape(RoundedRectangle(cornerRadius: 3.574))
    }

    // MARK: - Results list

    // Figma rows are 60pt tall; cap visible at 8 → 480pt. Scroll when results > 8.
    private static let rowHeight: CGFloat = 60
    private static let maxVisibleRows = 8

    @ViewBuilder
    private var resultsList: some View {
        if isLoading {
            loadingIndicator
        } else if results.isEmpty {
            RecipientEmptyState()
        } else {
            // Shrink list height to fit when results < maxVisibleRows; scroll otherwise.
            let visibleRows = min(results.count, Self.maxVisibleRows)
            let listHeight = Self.rowHeight * CGFloat(visibleRows)

            ScrollView(.vertical, showsIndicators: results.count > Self.maxVisibleRows) {
                // Rows are displayed contiguous (no spacing between them), matching
                // Figma where B.1 ends at y=277 and B.3 starts at y=277 with no gap.
                VStack(spacing: 0) {
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, profile in
                        Button {
                            onSelectRecipient(profile)
                        } label: {
                            RecipientRow(
                                profile: profile,
                                isHighlighted: index == 0   // B.1 gold tint on first result only
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("kudos.create.recipientRow.\(profile.id)")

                        // Thin divider between rows (not at the bottom of the last row)
                        if index < results.count - 1 {
                            Divider()
                                .background(
                                    Color(red: 153.0/255, green: 140.0/255, blue: 95.0/255)
                                        .opacity(0.3)
                                )
                        }
                    }
                }
            }
            .frame(height: listHeight)
        }
    }

    // MARK: - Loading indicator

    private var loadingIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
                .tint(Color(red: 153.0/255, green: 140.0/255, blue: 95.0/255))
                .padding(.vertical, 20)
            Spacer()
        }
    }
}

// MARK: - Preview

#if DEBUG

private struct RecipientDropdownPreviewContainer: View {
    @State private var query: String = "Dương"
    @State private var selectedProfile: ProfileSummary? = nil

    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Simulates the recipient input row above the dropdown
                HStack {
                    Text("Người nhận")
                        .font(.custom("Montserrat-Medium", size: 14))
                        .foregroundColor(Color(red: 0, green: 16.0/255, blue: 26.0/255))
                    Text("*")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 207.0/255, green: 19.0/255, blue: 34.0/255))
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 8)

                RecipientDropdown(
                    query: query,
                    results: ProfileSummary.mockResults,
                    isLoading: false,
                    onQueryChange: { query = $0 },
                    onSelectRecipient: { selectedProfile = $0 },
                    onDismiss: {}
                )
                .padding(.leading, 32)
            }
            .padding(.top, 60)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview("With results") {
    RecipientDropdownPreviewContainer()
}

#Preview("Empty state") {
    VStack(alignment: .leading, spacing: 0) {
        Spacer().frame(height: 60)
        RecipientDropdown(
            query: "xyz",
            results: [],
            isLoading: false,
            onQueryChange: { _ in },
            onSelectRecipient: { _ in },
            onDismiss: {}
        )
        .padding(.leading, 32)
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(red: 0, green: 16.0/255, blue: 26.0/255))
    .preferredColorScheme(.dark)
}

#Preview("Loading") {
    VStack(alignment: .leading, spacing: 0) {
        Spacer().frame(height: 60)
        RecipientDropdown(
            query: "Dương",
            results: [],
            isLoading: true,
            onQueryChange: { _ in },
            onSelectRecipient: { _ in },
            onDismiss: {}
        )
        .padding(.leading, 32)
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(red: 0, green: 16.0/255, blue: 26.0/255))
    .preferredColorScheme(.dark)
}
#endif
