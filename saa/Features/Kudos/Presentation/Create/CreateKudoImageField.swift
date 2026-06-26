import SwiftUI

// MARK: - CreateKudoImageField
// Figma nodes 6885:9346/9347/9350/9351/9357
// Layout: HStack(spacing: 12), "Image" label 46pt wide, then column of thumbnail row + add button
// Thumbnail: 32×32pt, border 0.447pt #998C5F, cornerRadius 8.043pt, white bg
// Delete badge: 8×8pt red circle top-right corner, "×" icon
// Add button: "Image (Tối đa 5)" label with plus icon, same chip style
// Max images: 5 (per clarifications)

struct CreateKudoImageField: View {

    // MARK: - Inputs

    let images: [ImageDraft]
    let onAddImage: () -> Void
    let onRemoveImage: (ImageDraft.ID) -> Void

    // MARK: - Constants

    private static let maxImages = 5
    private static let thumbnailSize: CGFloat = 32
    private static let thumbnailRadius: CGFloat = 8.043
    private static let badgeSize: CGFloat = 8

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            fieldLabel
            imageColumn
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("createKudo.image.row")
    }

    // MARK: - "Image" label (Figma 6885:9347/9348)
    // Montserrat-Regular 14pt, #00101A, lineHeight 12.51

    private var fieldLabel: some View {
        Text("Image")
            .font(.custom("Montserrat-Regular", size: 14))
            .foregroundColor(Color.createKudoText)
            .frame(width: 46, alignment: .leading)
            .frame(minHeight: Self.thumbnailSize)
    }

    // MARK: - Image column: thumbnail row + add button

    private var imageColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !images.isEmpty {
                thumbnailRow
            }
            addButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Thumbnail row (Figma 6885:9351)

    private var thumbnailRow: some View {
        HStack(spacing: 4) {
            ForEach(images) { draft in
                thumbnailCell(draft)
            }
        }
    }

    // MARK: - Single thumbnail cell with red delete badge

    private func thumbnailCell(_ draft: ImageDraft) -> some View {
        ZStack(alignment: .topTrailing) {
            // Thumbnail image (local file)
            AsyncImage(url: draft.localURL) { phase in
                switch phase {
                case .success(let img):
                    img.resizable()
                        .scaledToFill()
                        .frame(width: Self.thumbnailSize, height: Self.thumbnailSize)
                        .clipped()
                default:
                    Color.createKudoGold.opacity(0.3)
                }
            }
            .frame(width: Self.thumbnailSize, height: Self.thumbnailSize)
            .background(Color.createKudoFieldBg)
            .clipShape(RoundedRectangle(cornerRadius: Self.thumbnailRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Self.thumbnailRadius)
                    .stroke(Color.createKudoBorder, lineWidth: 0.447)
            )

            // Red delete badge (Figma: 8×8pt red circle, top-right offset)
            Button {
                onRemoveImage(draft.id)
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.createKudoDeleteRed)
                        .frame(width: Self.badgeSize, height: Self.badgeSize)
                    Image(systemName: "xmark")
                        .font(.system(size: 4, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .offset(x: Self.badgeSize / 2, y: -(Self.badgeSize / 2))
            .accessibilityIdentifier("createKudo.image.remove.\(draft.id)")
        }
        .frame(width: Self.thumbnailSize, height: Self.thumbnailSize)
    }

    // MARK: - Add-image button (Figma 6885:9357)
    // Visible when images.count < 5; shows "Image (Tối đa 5)" + plus icon

    @ViewBuilder
    private var addButton: some View {
        if images.count < Self.maxImages {
            Button(action: onAddImage) {
                HStack(spacing: 1.787) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.createKudoText)
                        .frame(width: 16, height: 16)

                    (
                        Text("Image")
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
                        .stroke(Color.createKudoBorder, lineWidth: 0.447)
                )
                .clipShape(RoundedRectangle(cornerRadius: 3.574))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("createKudo.image.add")
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("empty") {
    CreateKudoImageField(images: [], onAddImage: {}, onRemoveImage: { _ in })
        .padding()
        .background(Color.createKudoCardBg)
}

#Preview("with images") {
    // Use placeholder local URLs for preview (real files loaded in prod)
    let drafts = (0..<3).map { _ in ImageDraft(id: UUID(), localURL: URL(string: "file:///dev/null")!) }
    return CreateKudoImageField(images: drafts, onAddImage: {}, onRemoveImage: { _ in })
        .padding()
        .background(Color.createKudoCardBg)
}
#endif
