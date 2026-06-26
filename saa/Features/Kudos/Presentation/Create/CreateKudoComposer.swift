import SwiftUI

// MARK: - CreateKudoComposer

/// Composition root that wires `CreateKudoViewModel` to live dependencies and
/// returns a ready-to-present `CreateKudoViewContainer`.
///
/// Called from `WriteKudoFormStubView` (the stable entry-point used by existing
/// routing code) and `KudosViewContainer` via the `onSendKudos` callback.
///
/// The `onKudosCreated` callback is handed up to `KudosViewContainer`, which
/// forwards it to `KudosViewModel.prependKudos(_:)` for optimistic feed refresh.
enum CreateKudoComposer {

    /// Builds the full view hierarchy with all dependencies injected.
    ///
    /// - Parameters:
    ///   - repo: Repository conforming to `KudosRepositoryProtocol`.
    ///   - uploader: Uploader conforming to `KudosImageUploaderProtocol`.
    ///   - onKudosCreated: Called with the new `Kudos` on successful submission.
    ///   - onDismiss: Called when the form should close (cancel or post-success).
    /// - Returns: A fully wired `CreateKudoViewContainer` ready for `.fullScreenCover`.
    @MainActor
    static func make(
        repo: any KudosRepositoryProtocol,
        uploader: any KudosImageUploaderProtocol,
        onKudosCreated: @escaping (Kudos) -> Void,
        onDismiss: @escaping () -> Void
    ) async -> CreateKudoViewContainer {
        let currentUserId = await repo.currentUserId() ?? UUID()
        let vm = CreateKudoViewModel(
            repo: repo,
            uploader: uploader,
            currentUserId: currentUserId,
            onKudosCreated: onKudosCreated
        )
        return CreateKudoViewContainer(viewModel: vm, onDismiss: onDismiss)
    }
}
