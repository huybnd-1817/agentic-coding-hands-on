import Foundation
import Supabase

/// Provides a shared `SupabaseClient` singleton initialized from compile-time
/// environment values (`Environment.supabaseURL`, `Environment.supabaseAnonKey`).
///
/// The SDK defaults to Keychain-backed session storage scoped to the app's
/// bundle identifier. No custom `AuthLocalStorage` is configured here — the
/// default is sufficient and avoids stale-session pitfalls across build variants.
///
/// Usage:
///   let client = SupabaseClientProvider.shared
enum SupabaseClientProvider {
    static let shared: SupabaseClient = SupabaseClient(
        supabaseURL: Environment.supabaseURL,
        supabaseKey: Environment.supabaseAnonKey
    )
}
