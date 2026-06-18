import SwiftUI

// MARK: - AccessDeniedView

/// Terminal screen surfaced when the Home data layer reports a 403 (TC_ACC_004).
///
/// Per clarification 2026-06-15 Q7: minimal stub — title, message, and an
/// explicit sign-out button (the user controls when their session ends; no
/// silent retry). String keys land via Phase 05's xcstrings additions.
struct AccessDeniedView: View {

    let signOutUseCase: SignOutUseCase

    @State private var isSigningOut = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "exclamationmark.shield")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(.secondary)

            Text(LocalizedStringKey("accessDenied.title"))
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)

            Text(LocalizedStringKey("accessDenied.message"))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                guard !isSigningOut else { return }
                isSigningOut = true
                Task {
                    await signOutUseCase.execute()
                    isSigningOut = false
                }
            } label: {
                Text(LocalizedStringKey("accessDenied.signOut"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
            .accessibilityIdentifier("accessDenied.signOutButton")
            .disabled(isSigningOut)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("accessDenied.root")
    }
}

#if DEBUG
#Preview {
    let store = AuthSessionStore()
    store.injectState(state: .preview, isRestoring: false, isAccessDenied: true)
    let repo = NoopAuthRepository()
    let google = NoopGoogleSignInService()
    return AccessDeniedView(
        signOutUseCase: SignOutUseCase(repository: repo, googleService: google, store: store)
    )
    .environmentObject(store)
}
#endif
