import SwiftUI

// MARK: - CreateKudoHashtagField
// Figma node 6885:9324 — E row: "Hashtag *" label + tag chips + add button
// Default state: label + single "+" add-button chip (height 32pt)
// Filled state (PV7jBVZU1N 6885:9936): label + wrap-flow chips with × remove + add button
// Layout: HStack(spacing: 12), label fixed 70pt, chips fill remainder in wrapping rows

struct CreateKudoHashtagField: View {

    // MARK: - Inputs

    let hashtags: [Hashtag]
    let hasError: Bool
    let onOpenPicker: () -> Void
    let onRemove: (Hashtag) -> Void

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            fieldLabel
            tagsArea
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("createKudo.hashtag.row")
    }

    // MARK: - Label (B.1 pattern) — "Hashtag *"

    private var fieldLabel: some View {
        HStack(spacing: 1) {
            Text("Hashtag")
                .font(.custom("Montserrat-Medium", size: 14))
                .foregroundColor(Color.createKudoText)
            Text("*")
                .font(.custom("NotoSansJP-Bold", size: 14))
                .foregroundColor(Color.createKudoRequired)
        }
        .frame(width: 70, alignment: .leading)
        .frame(minHeight: 32)
    }

    // MARK: - Tags area (chips + add button, wrapping)

    private var tagsArea: some View {
        FlowLayout(spacing: 4) {
            ForEach(hashtags) { tag in
                tagChip(tag)
            }
            addButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Individual tag chip with × remove button

    private func tagChip(_ tag: Hashtag) -> some View {
        HStack(spacing: 3.574) {
            Text(tag.tag)
                .font(.custom("Montserrat-Regular", size: 12))
                .foregroundColor(Color.createKudoText)
                .lineLimit(1)

            Button {
                onRemove(tag)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Color.createKudoText)
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("createKudo.hashtag.remove.\(tag.tag)")
        }
        .padding(.horizontal, 3.574)
        .padding(.vertical, 1.787)
        .frame(height: 32)
        .background(Color.createKudoFieldBg)
        .overlay(
            RoundedRectangle(cornerRadius: 3.574)
                .stroke(Color.createKudoBorder, lineWidth: 0.447)
        )
        .clipShape(RoundedRectangle(cornerRadius: 3.574))
    }

    // MARK: - Add button (Figma 6885:9340/9341 — icon + "Hashtag (Tối đa 5)" pill)

    private var addButton: some View {
        Button(action: onOpenPicker) {
            HStack(spacing: 1.787) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.createKudoText)
                    .frame(width: 16, height: 16)

                (
                    Text("Hashtag")
                        .foregroundColor(Color.createKudoText)
                    + Text(" (Tối đa 5)")
                        .foregroundColor(Color.createKudoPlaceholder)
                )
                .font(.custom("Montserrat-Regular", size: 12))
                .lineLimit(1)
            }
            .padding(.horizontal, 3.574)
            .padding(.vertical, 1.787)
            .frame(height: 32)
            .background(Color.createKudoFieldBg)
            .overlay(
                RoundedRectangle(cornerRadius: 3.574)
                    .stroke(hasError ? Color.createKudoRequired : Color.createKudoBorder, lineWidth: 0.447)
            )
            .clipShape(RoundedRectangle(cornerRadius: 3.574))
        }
        .buttonStyle(.plain)
        // Publish this button's frame so `CreateKudoViewContainer` can anchor the
        // hashtag dropdown 4pt above it, regardless of how chips wrap above.
        .anchorPreference(key: HashtagAddButtonAnchorKey.self, value: .bounds) { $0 }
        .accessibilityIdentifier("createKudo.hashtag.add")
    }
}

// MARK: - HashtagAddButtonAnchorKey

/// Carries the add-hashtag button's frame anchor up to the view hierarchy so
/// the dropdown overlay can position itself relative to the button without
/// hard-coding form-layout math.
struct HashtagAddButtonAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}

// MARK: - Preview

#if DEBUG
private let mockHashtags: [Hashtag] = [
    Hashtag(id: UUID(), tag: "#Dedicated"),
    Hashtag(id: UUID(), tag: "#Inspiring"),
    Hashtag(id: UUID(), tag: "#Teamwork")
]

#Preview("empty") {
    CreateKudoHashtagField(
        hashtags: [],
        hasError: false,
        onOpenPicker: {},
        onRemove: { _ in }
    )
    .padding()
    .background(Color.createKudoCardBg)
}

#Preview("filled") {
    CreateKudoHashtagField(
        hashtags: mockHashtags,
        hasError: false,
        onOpenPicker: {},
        onRemove: { _ in }
    )
    .padding()
    .background(Color.createKudoCardBg)
}
#endif
