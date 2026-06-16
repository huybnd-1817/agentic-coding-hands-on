import SwiftUI
import GoogleSignIn

@main
struct saaApp: App {

    @StateObject private var authSession: AuthSessionStore
    @StateObject private var languagePreference = LanguagePreference()

    private let restoreUseCase: RestoreSessionUseCase
    private let signOutUseCase: SignOutUseCase
    private let loginViewModel: LoginViewModel

    // Home feature graph
    private let awardsRepository: any AwardsRepositoryProtocol
    private let notificationStore = NotificationStubStore()

    init() {
        Self.configureGoogleSignIn()

        let store = AuthSessionStore()
        let repo: any AuthRepositoryProtocol
        let google: any GoogleSignInServiceProtocol

        #if DEBUG
        let scenarioName = Self.uiTestScenario()
        if scenarioName != nil {
            repo = NoopAuthRepository()
            google = NoopGoogleSignInService()
        } else {
            repo = SupabaseAuthRepository()
            google = GoogleSignInService()
        }
        #else
        repo = SupabaseAuthRepository()
        google = GoogleSignInService()
        #endif

        let signInUseCase = SignInWithGoogleUseCase(repository: repo, googleService: google, nonceGenerator: Nonce.default)
        let vm = LoginViewModel(signInUseCase: signInUseCase, store: store)

        #if DEBUG
        if let scenario = scenarioName {
            Self.applyScenario(scenario, to: store, loginViewModel: vm)
        }
        #endif

        _authSession = StateObject(wrappedValue: store)
        restoreUseCase = RestoreSessionUseCase(repository: repo)
        signOutUseCase = SignOutUseCase(repository: repo, googleService: google, store: store)
        loginViewModel = vm

        // Home feature: Supabase-backed in all builds. UI-test scenarios still
        // exercise the live wiring against the test runner's network stack —
        // mock injection happens at the repository level when needed later.
        awardsRepository = SupabaseAwardsRepository()
    }

    var body: some Scene {
        WindowGroup {
            AppRouter(
                loginViewModel: loginViewModel,
                signOutUseCase: signOutUseCase,
                makeHomeRoot: makeHomeRoot
            )
            .environmentObject(authSession)
            .environmentObject(languagePreference)
            .environment(\.locale, Locale(identifier: languagePreference.current.localeIdentifier))
            .task {
                #if DEBUG
                if Self.uiTestScenario() != nil { return }
                #endif
                authSession.setRestoring(true)
                authSession.setState(try? await restoreUseCase.execute())
                authSession.setRestoring(false)
            }
            .onOpenURL { GIDSignIn.sharedInstance.handle($0) }
        }
    }

    // MARK: - Home composition

    /// Builds the Home tab root. Returns an `AnyView` so `AppRouter` stays
    /// view-type-agnostic and only depends on the closure shape.
    private func makeHomeRoot() -> AnyView {
        let container = HomeViewContainer(
            viewModel: HomeViewModel(
                repository: awardsRepository,
                notificationStore: notificationStore
            ),
            signOutUseCase: signOutUseCase
        )
        return AnyView(MainTabView(home: container))
    }
}
