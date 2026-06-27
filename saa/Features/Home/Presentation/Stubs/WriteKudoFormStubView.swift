import SwiftUI

// MARK: - WriteKudoFormStubView
//
// Entry-point view for the Create Kudo flow. File path and exported type name
// are kept stable so existing routing code (Home tab + Kudos tab Send button)
// requires no changes.
//
// In production: injects SupabaseKudosRepository + SupabaseStorageImageUploader.
// In DEBUG UI-test mode (kudos.create): injects MockKudosRepository +
//   MockKudosImageUploader so the form works without network I/O.
//
// `onKudosCreated` and `onDismiss` are passed in by the caller so this view
// stays decoupled from any specific feed or navigation stack.

struct WriteKudoFormStubView: View {

    // MARK: - Callbacks

    let onKudosCreated: (Kudos) -> Void
    let onDismiss: () -> Void

    // MARK: - Composer output state

    @State private var container: CreateKudoViewContainer?

    // MARK: - Body

    var body: some View {
        Group {
            if let container {
                container
            } else {
                // Brief loading state while the async composer resolves currentUserId.
                ZStack {
                    Color(red: 0, green: 16/255, blue: 26/255).ignoresSafeArea()
                    ProgressView()
                        .tint(.white)
                }
                .task {
                    await buildContainer()
                }
            }
        }
    }

    // MARK: - Build

    @MainActor
    private func buildContainer() async {
        let repo: any KudosRepositoryProtocol
        let uploader: any KudosImageUploaderProtocol

        #if DEBUG
        if Self.isUITestCreateMode() {
            repo = MockKudosRepository()
            uploader = MockKudosImageUploader()
        } else {
            repo = SupabaseKudosRepository()
            uploader = SupabaseStorageImageUploader()
        }
        #else
        repo = SupabaseKudosRepository()
        uploader = SupabaseStorageImageUploader()
        #endif

        container = await CreateKudoComposer.make(
            repo: repo,
            uploader: uploader,
            onKudosCreated: onKudosCreated,
            onDismiss: onDismiss
        )
    }

    // MARK: - UI-test helpers

    #if DEBUG
    /// Returns true when the app was launched with `-uiTestMode kudos.create`.
    private static func isUITestCreateMode() -> Bool {
        let args = CommandLine.arguments
        guard let idx = args.firstIndex(of: "-uiTestMode"), idx + 1 < args.count else {
            return false
        }
        return args[idx + 1] == "kudos.create"
    }
    #endif
}
