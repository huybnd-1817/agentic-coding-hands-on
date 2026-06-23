import Foundation

// MARK: - saaApp Kudos composition helpers

/// Builds the Kudos feature object graph.
///
/// Extracted from `saaApp.swift` to keep that file under the 80-LoC cap,
/// following the same pattern as `saaApp+Setup.swift` for the auth graph.
///
/// Production: `SupabaseKudosRepository` (Supabase-backed).
/// UI-test (`-uiTestMode`): `MockKudosRepository` so the Kudos tab reaches
/// `.loaded` on the first frame without network I/O.
extension saaApp {

    // MARK: - Factory

    /// Constructs the Kudos feature graph.
    ///
    /// Returns a fully-wired `KudosViewModel` ready to be injected into
    /// `KudosViewContainer`. Both use-cases share the same repository instance.
    static func makeKudosViewModel(scenarioName: String?) -> KudosViewModel {
        let repo = makeKudosRepository(scenarioName: scenarioName)
        let loadUseCase = LoadKudosScreenUseCase(repository: repo)
        let toggleReactionUseCase = ToggleKudosReactionUseCase(repository: repo)
        let clipboard: any KudosClipboardServicing = UIKitKudosClipboardService()
        return KudosViewModel(
            loadUseCase: loadUseCase,
            toggleReactionUseCase: toggleReactionUseCase,
            clipboard: clipboard
        )
    }

    // MARK: - Repository selection

    private static func makeKudosRepository(scenarioName: String?) -> any KudosRepositoryProtocol {
        #if DEBUG
        if scenarioName != nil {
            return MockKudosRepository()
        }
        #endif
        return SupabaseKudosRepository()
    }
}
