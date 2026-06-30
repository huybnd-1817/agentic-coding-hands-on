import SwiftUI

// MARK: - ImageLightboxView

/// Fullscreen pager for kudo attachment images. `.fullScreenCover` content.
/// No pinch-to-zoom (deferred); no caching beyond `AsyncImage`.
@MainActor
struct ImageLightboxView: View {

    // MARK: - Inputs

    let imageURLs: [URL]
    let initialIndex: Int
    let onDismiss: () -> Void

    // MARK: - State

    @State private var currentIndex: Int

    // MARK: - Init

    init(imageURLs: [URL], initialIndex: Int = 0, onDismiss: @escaping () -> Void) {
        self.imageURLs = imageURLs
        self.initialIndex = initialIndex
        self.onDismiss = onDismiss
        // Defensive clamp — out-of-range indexes would crash TabView.
        let clamped = max(0, min(initialIndex, max(imageURLs.count - 1, 0)))
        _currentIndex = State(initialValue: clamped)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(imageURLs.enumerated()), id: \.offset) { idx, url in
                    pagerImage(url)
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: imageURLs.count > 1 ? .automatic : .never))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .ignoresSafeArea()
            // Identifier on the TabView (NOT outer ZStack) so SwiftUI's
            // identifier-propagation does NOT shadow `kudos.detail.lightbox.close`
            // on the sibling close button. Same shadowing fix applied to
            // ViewKudoDetailView and KudosAuthorProfileStubView.
            .accessibilityIdentifier("kudos.detail.lightbox.root")

            closeButton
        }
    }

    // MARK: - Subviews

    private func pagerImage(_ url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failure:
                Image(systemName: "photo")
                    .font(.system(size: 48))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            @unknown default:
                EmptyView()
            }
        }
    }

    private var closeButton: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.black.opacity(0.4))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
        .padding(.trailing, 16)
        .accessibilityLabel(Text(LocalizedStringKey("kudos.detail.lightbox.close")))
        .accessibilityIdentifier("kudos.detail.lightbox.close")
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Lightbox") {
    ImageLightboxView(
        imageURLs: [
            URL(string: "https://picsum.photos/seed/kudo1/600/800")!,
            URL(string: "https://picsum.photos/seed/kudo2/600/800")!,
            URL(string: "https://picsum.photos/seed/kudo3/600/800")!
        ],
        initialIndex: 0,
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
#endif
