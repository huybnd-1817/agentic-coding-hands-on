import SwiftUI

// MARK: - HomeViewContainer

/// Integration root for the Home feature. Owns the `HomeViewModel`, observes
/// its state, dispatches navigation closures into `HomeView`, and routes auth
/// failures (401 → sign-out, 403 → AccessDenied) through `AuthSessionStore`.
///
/// `HomeView` remains pure-presentational; everything VM- or navigation-aware
/// lives in this file. Stub destinations (Phase 06) are pushed via a single
/// `NavigationStack` path. Language selection is now an inline dropdown
/// rendered by `LanguagePicker` inside the header — no sheet involved.
///
/// Cross-tab navigation (Phase 09): owns `activeTab` state and passes it to
/// `MainTabView` via `externalSelection`. `HomeView.onKudosDetail` mutates
/// `activeTab = .kudos` to switch the tab-bar from outside `MainTabView`.
struct HomeViewContainer: View {

    // MARK: - Dependencies

    @StateObject private var viewModel: HomeViewModel
    @EnvironmentObject private var authSession: AuthSessionStore
    @EnvironmentObject private var languagePreference: LanguagePreference

    let signOutUseCase: SignOutUseCase

    /// Passed to `MainTabView(kudosViewModel:)` so the Kudos tab mounts the
    /// real VM-backed container rather than a stub.
    let kudosViewModel: KudosViewModel

    // MARK: - Navigation state

    /// Typed-array `NavigationStack` path so we can inspect the current top of
    /// stack. Plain `NavigationPath` does not expose its contents, but we need
    /// `path.last` to gate FAB pencil double-tap (TC_FUN_013): when XCUITest
    /// fires `doubleTap()` the two events land in the same SwiftUI runloop
    /// frame, beating any `@State Bool` gate the FAB might hold.
    @State private var path: [HomeRoute] = []

    /// Drives `MainTabView` tab selection from this container.
    /// Mutated by `onKudosDetail` to switch to the Kudos tab.
    @State private var activeTab: NavTab = .home

    // MARK: - Init

    /// `@autoclosure` keeps the VM construction deferred until `@StateObject`
    /// captures it once for the view's lifetime.
    init(
        viewModel: @autoclosure @escaping () -> HomeViewModel,
        signOutUseCase: SignOutUseCase,
        kudosViewModel: KudosViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.signOutUseCase = signOutUseCase
        self.kudosViewModel = kudosViewModel
    }

    // MARK: - Body

    var body: some View {
        MainTabView(
            home: homeStack,
            externalSelection: $activeTab,
            kudosViewModel: kudosViewModel
        )
    }

    // MARK: - Home NavigationStack (isolated so MainTabView generic param stays stable)

    private var homeStack: some View {
        NavigationStack(path: $path) {
            HomeView(
                signOutUseCase: signOutUseCase,
                awardsState: viewModel.state,
                countdown: viewModel.countdown,
                unreadCount: viewModel.unreadCount,
                isKudosAvailable: viewModel.isKudosAvailable,
                eventDateText: viewModel.eventDateText,
                venueName: viewModel.venueName,
                selectedLanguage: $languagePreference.current,
                onAboutAward:     { push(.awardsOverview) },
                onAboutKudos:     { push(.kudosOverview) },
                onAwardDetail:    { id in push(.awardDetail(id)) },
                onRetryAwards:    { Task { await viewModel.retryAwards() } },
                onKudosDetail:    { activeTab = .kudos },
                onBellTap:        { push(.notifications) },
                onSearchTap:      { push(.search) },
                onLanguageChange: { languagePreference.current = $0 },
                onFabPencilTap:   { push(.writeKudo) },
                onFabKudosTap:    { push(.kudosFeed) }
            )
            .navigationDestination(for: HomeRoute.self, destination: destination)
        }
        .task {
            viewModel.startCountdownTimer()
            await viewModel.loadAwards()
        }
        .onDisappear {
            viewModel.stopCountdownTimer()
        }
        .onChange(of: viewModel.state) { newState in
            if case .error(let error) = newState {
                handleAwardsError(error)
            }
        }
    }

    // MARK: - Routing

    /// Pushes a destination while skipping no-op double-pushes (TC_FUN_013).
    /// Synchronous `path.last` read on a typed `[HomeRoute]` array makes this
    /// race-free even when two taps fire in the same runloop frame.
    private func push(_ route: HomeRoute) {
        guard path.last != route else { return }
        path.append(route)
    }

    @ViewBuilder
    private func destination(for route: HomeRoute) -> some View {
        switch route {
        case .awardsOverview:   AwardsOverviewStubView()
        case .awardDetail(let id): AwardDetailStubView(awardId: id)
        case .kudosOverview:    KudosOverviewStubView()
        case .kudosDetail:      KudosDetailStubView()
        case .kudosFeed:        KudosFeedStubView()
        case .writeKudo:        WriteKudoFormStubView()
        case .notifications:    NotificationsPanelStubView()
        case .search:           SearchStubView()
        }
    }

    // MARK: - Error handling

    /// 401 → clear session (lands on Login); 403 → set Access Denied flag
    /// (router switches to AccessDeniedView). All other errors stay surfaced in
    /// the UI as the retry-capable error state.
    private func handleAwardsError(_ error: AwardsError) {
        switch error {
        case .unauthorized:
            Task { await signOutUseCase.execute() }
        case .forbidden:
            authSession.setAccessDenied(true)
        case .network, .unknown:
            break
        }
    }
}

// MARK: - HomeRoute

/// All push destinations available from HomeView. Hashable so it slots into
/// `NavigationPath` and `navigationDestination(for:)`.
enum HomeRoute: Hashable {
    case awardsOverview
    case awardDetail(UUID)
    case kudosOverview
    case kudosDetail
    case kudosFeed
    case writeKudo
    case notifications
    case search
}
