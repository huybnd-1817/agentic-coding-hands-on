import SwiftUI
import PhotosUI
import UIKit

// MARK: - CreateKudoViewContainer

/// Stateful wrapper that owns `CreateKudoViewModel` and bridges it to
/// `CreateKudoView`. Handles:
///   - Recipient dropdown overlay (presented over the form card)
///   - Hashtag dropdown overlay
///   - PhotosPicker sheet
///   - Cancel confirmation dialog
///   - Success-driven dismiss + feed callback
///   - Toast rendering
///
/// Presented as `.fullScreenCover` from `WriteKudoFormStubView`.
@MainActor
struct CreateKudoViewContainer: View {

    // MARK: - ViewModel

    @StateObject var viewModel: CreateKudoViewModel

    // MARK: - Dismiss callback (injected by composer)

    let onDismiss: () -> Void

    // MARK: - Local overlay state

    @State private var isRecipientDropdownOpen = false
    @State private var isPhotoPickerPresented = false
    @State private var showCancelConfirm = false
    @State private var photoPickerItems: [PhotosPickerItem] = []

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            CreateKudoView(
                recipient: viewModel.recipient,
                title: viewModel.title,
                message: viewModel.message,
                hashtags: viewModel.selectedHashtags,
                images: viewModel.images,
                isAnonymous: viewModel.isAnonymous,
                anonymousNickname: viewModel.anonymousNickname,
                isSubmitting: viewModel.isSubmitting,
                errors: viewModel.errors,
                showRequiredFieldsError: viewModel.showRequiredFieldsError,
                onOpenRecipientPicker: { isRecipientDropdownOpen = true },
                onTitleChange: { viewModel.setTitle($0) },
                onMessageChange: { viewModel.setMessage($0) },
                onApplyMarkdown: { viewModel.applyMarkdown($0) },
                onOpenHashtagPicker: { viewModel.openHashtagPicker() },
                onRemoveHashtag: { viewModel.removeHashtag($0) },
                onAddImage: { isPhotoPickerPresented = true },
                onRemoveImage: { viewModel.removeImage($0) },
                onToggleAnonymous: { viewModel.toggleAnonymous() },
                onNicknameChange: { viewModel.setNickname($0) },
                onTapStandards: { viewModel.onTapStandards() },
                onCancel: handleCancel,
                onSubmit: { Task { await viewModel.submit() } }
            )

            // Recipient dropdown overlay — shown above the form
            if isRecipientDropdownOpen {
                recipientDropdownOverlay
            }

            // Toast overlay
            if let key = viewModel.toastMessageKey {
                toastOverlay(key: key)
            }
        }
        // Hashtag dropdown overlay — anchored to the add-hashtag button's frame
        // (captured via `HashtagAddButtonAnchorKey`) so it tracks the button no
        // matter how chips wrap above it.
        .overlayPreferenceValue(HashtagAddButtonAnchorKey.self) { anchor in
            if viewModel.isHashtagPickerOpen {
                hashtagDropdownOverlay(anchor: anchor)
            }
        }
        .photosPicker(
            isPresented: $isPhotoPickerPresented,
            selection: $photoPickerItems,
            maxSelectionCount: max(1, 5 - viewModel.images.count),
            matching: .images
        )
        .onChange(of: photoPickerItems) { items in
            handlePhotoPickerItems(items)
        }
        .confirmationDialog(
            LocalizedStringKey("kudos.create.cancel.confirm.title"),
            isPresented: $showCancelConfirm,
            titleVisibility: .visible
        ) {
            Button(
                LocalizedStringKey("kudos.create.cancel.confirm.discard"),
                role: .destructive
            ) {
                onDismiss()
            }
            Button(LocalizedStringKey("kudos.create.cancel.confirm.keep"), role: .cancel) {}
        }
        .onChange(of: viewModel.submissionState) { state in
            if case .succeeded = state {
                onDismiss()
            }
        }
        .task { await viewModel.onAppear() }
        .accessibilityIdentifier("createKudo.root")
    }

    // MARK: - Recipient dropdown overlay
    // Anchored 4pt below recipient row.
    // Form layout: nav 89 + top padding 24 + card padding 18 + header 24 + gap 16
    // + recipient row 40 = 211pt → 4pt gap → dropdown top at 215pt.
    // Horizontal: form card padding 20pt + 12pt inset = 32pt from screen edge.
    // `ignoresSafeArea(edges: .top)` matches CreateKudoView's coordinate system
    // so the absolute spacer counts from screen top, not from below the status bar.

    private var recipientDropdownOverlay: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 215)

            RecipientDropdown(
                query: viewModel.recipientQuery,
                results: viewModel.filteredRecipients,
                isLoading: viewModel.isRecipientsLoading,
                onQueryChange: { viewModel.recipientQuery = $0 },
                onSelectRecipient: {
                    viewModel.selectRecipient($0)
                    isRecipientDropdownOpen = false
                },
                onDismiss: { isRecipientDropdownOpen = false }
            )
            .padding(.horizontal, 32)

            Spacer()
        }
        .ignoresSafeArea(edges: .top)
        .contentShape(Rectangle())
        .onTapGesture { isRecipientDropdownOpen = false }
    }

    // MARK: - Hashtag dropdown overlay
    // Anchored 4pt above the Add-hashtag button using the button's published
    // frame anchor (`HashtagAddButtonAnchorKey`). A bottom-anchored spacer of
    // height `(geometryHeight - buttonMinY + 4)` places the dropdown's bottom
    // edge at `buttonMinY - 4`, so the dropdown tracks the button no matter how
    // chip rows wrap above it.

    private func hashtagDropdownOverlay(anchor: Anchor<CGRect>?) -> some View {
        GeometryReader { proxy in
            if let anchor = anchor {
                let buttonMinY = proxy[anchor].minY
                let bottomSpacer = max(0, proxy.size.height - buttonMinY + 4)

                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    HashtagDropdown(
                        hashtags: viewModel.availableHashtags,
                        selectedIds: Set(viewModel.selectedHashtags.map(\.id)),
                        isAtMax: viewModel.isHashtagAtMax,
                        onToggleHashtag: { viewModel.toggleHashtag($0) },
                        onDismiss: { viewModel.dismissHashtagPicker() }
                    )
                    .padding(.horizontal, 32)

                    Color.clear.frame(height: bottomSpacer)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { viewModel.dismissHashtagPicker() }
            }
        }
    }

    // MARK: - Toast overlay

    private func toastOverlay(key: String) -> some View {
        VStack {
            Spacer()
            Text(LocalizedStringKey(key))
                .font(.custom("Montserrat-Regular", size: 14))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.8))
                .clipShape(Capsule())
                .padding(.bottom, 60)
                .accessibilityIdentifier("createKudo.toast")
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.25), value: key)
    }

    // MARK: - Cancel handling

    private func handleCancel() {
        switch viewModel.attemptCancel() {
        case .canDismiss:
            onDismiss()
        case .confirmFirst:
            showCancelConfirm = true
        }
    }

    // MARK: - PhotosPicker → VM

    private func handlePhotoPickerItems(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        photoPickerItems = []
        for item in items {
            Task {
                await loadAndAddImage(item: item)
            }
        }
    }

    private func loadAndAddImage(item: PhotosPickerItem) async {
        guard let rawData = try? await item.loadTransferable(type: Data.self) else { return }

        // Detect content type from magic bytes: PNG starts with \x89PNG, JPEG with \xFF\xD8.
        let isPNG = rawData.prefix(4) == Data([0x89, 0x50, 0x4E, 0x47])
        let sourceContentType = isPNG ? "image/png" : "image/jpeg"

        // Downsize if wider than 2048px (clarifications §image-upload).
        // Fall back to the raw bytes when decoding/encoding fails.
        let resized = UIImage(data: rawData).flatMap {
            KudosImageResizer.resizeIfNeeded($0, sourceContentType: sourceContentType)
        }
        let finalData = resized?.data ?? rawData
        let finalContentType = resized?.contentType ?? sourceContentType

        let draft = KudosImageDraft(data: finalData, contentType: finalContentType)
        let localURL = saveToTemp(data: finalData, draftId: draft.id)
        viewModel.addImage(localURL: localURL, domain: draft)
    }

    /// Writes image bytes to a temp file so `AsyncImage` can render the thumbnail.
    private func saveToTemp(data: Data, draftId: UUID) -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("kudos-draft-\(draftId.uuidString).jpg")
        try? data.write(to: url)
        return url
    }
}
