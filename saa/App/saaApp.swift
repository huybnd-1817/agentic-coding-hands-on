import SwiftUI
import GoogleSignIn

@main
struct saaApp: App {

    @StateObject private var authSession: AuthSessionStore
    @StateObject private var languagePreference = LanguagePreference()

    private let restoreUseCase: RestoreSessionUseCase
    let signOutUseCase: SignOutUseCase  // internal: accessed by saaApp+HomeSetup.swift
    private let loginViewModel: LoginViewModel

    // Home + Kudos graphs — internal so saaApp+HomeSetup.swift can read them.
    let awardsRepository: any AwardsRepositoryProtocol
    let notificationStore = NotificationStubStore()
    let kudosViewModel: KudosViewModel

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

        // Home + Kudos graphs — see saaApp+HomeSetup.swift / saaApp+KudosSetup.swift.
        awardsRepository = Self.makeAwardsRepository(scenarioName: scenarioName)
        kudosViewModel = Self.makeKudosViewModel(scenarioName: scenarioName)
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
}
