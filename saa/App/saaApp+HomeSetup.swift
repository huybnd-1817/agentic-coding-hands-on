import SwiftUI

// MARK: - saaApp Home composition helpers

/// Builds the Home tab root view and the awards repository.
///
/// Extracted from `saaApp.swift` to keep that file under the 80-LoC cap,
/// following the same pattern as `saaApp+KudosSetup.swift` for the Kudos graph.
///
/// Awards repository selection:
/// - Production / dev: `SupabaseAwardsRepository` (real network I/O).
/// - UI-test (`-uiTestMode`): `MockAwardsRepository` so HomeView reaches
///   `.loaded` on the first frame. The AwardsLoadingView shimmer is a
///   `repeatForever` animation; if it runs while a URLSession waits on an
///   unreachable Supabase (CI uses stub xcconfig), the view tree never
///   quiesces and XCUITest taps on home-header elements race the 3s window.
extension saaApp {

    // MARK: - Repository factory

    static func makeAwardsRepository(scenarioName: String?) -> any AwardsRepositoryProtocol {
        #if DEBUG
        if let scenario = scenarioName {
            return MockAwardsRepository(behavior: awardsBehavior(for: scenario))
        }
        #endif
        return SupabaseAwardsRepository()
    }

    // MARK: - View factory

    /// Builds the Home tab root. Returns an `AnyView` so `AppRouter` stays
    /// view-type-agnostic and only depends on the closure shape.
    ///
    /// `HomeViewContainer.body` owns `MainTabView` (with `KudosViewContainer`
    /// wired inside). Wrapping it in `MainTabView` here would double-nest the
    /// tab bar — return the container directly as `AnyView`.
    func makeHomeRoot() -> AnyView {
        let container = HomeViewContainer(
            viewModel: HomeViewModel(
                repository: awardsRepository,
                notificationStore: notificationStore
            ),
            signOutUseCase: signOutUseCase,
            kudosViewModel: kudosViewModel
        )
        return AnyView(container)
    }
}
