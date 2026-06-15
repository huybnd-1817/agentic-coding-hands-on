import Foundation
import Supabase

/// Provides a shared `SupabaseClient` singleton initialized from compile-time
/// environment values (`Environment.supabaseURL`, `Environment.supabaseAnonKey`).
///
/// The SDK defaults to Keychain-backed session storage scoped to the app's
/// bundle identifier. No custom `AuthLocalStorage` is configured here — the
/// default is sufficient and avoids stale-session pitfalls across build variants.
///
/// `emitLocalSessionAsInitialSession: true` opts into supabase-swift's upcoming
/// behavior (will become default in the next major). `SupabaseAuthRepository.restoreSession()`
/// validates sessions via `try await client.auth.session`, which throws on expired
/// tokens — we do not rely on the legacy initial-session emission, so no
/// `session.isExpired` check is required at the call site.
///
/// Usage:
///   let client = SupabaseClientProvider.shared
enum SupabaseClientProvider {
    static let shared: SupabaseClient = SupabaseClient(
        supabaseURL: Environment.supabaseURL,
        supabaseKey: Environment.supabaseAnonKey,
        options: SupabaseClientOptions(
            auth: .init(emitLocalSessionAsInitialSession: true)
        )
    )
}
