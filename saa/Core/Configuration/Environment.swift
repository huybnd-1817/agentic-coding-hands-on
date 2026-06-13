import Foundation

/// Reads compile-time environment values injected via xcconfig → Info.plist substitution.
/// Keys must be present in Debug.xcconfig / Release.xcconfig and referenced in the
/// target's Info.plist (or INFOPLIST_KEY_* build setting rows).
///
/// Usage:
///   let client = SupabaseClient(supabaseURL: Environment.supabaseURL,
///                               supabaseKey: Environment.supabaseAnonKey)
enum Environment {

    // MARK: - Public Interface

    static let supabaseURL: URL = {
        guard let raw = value(for: "SUPABASE_URL"),
              let url = URL(string: raw) else {
            fatalError(
                "[Environment] Missing or invalid SUPABASE_URL — " +
                "copy saa/Configuration/Sample.xcconfig.example → Debug.xcconfig " +
                "and fill in your Supabase project URL."
            )
        }
        return url
    }()

    static let supabaseAnonKey: String = {
        guard let key = value(for: "SUPABASE_ANON_KEY"), !key.isEmpty else {
            fatalError(
                "[Environment] Missing SUPABASE_ANON_KEY — " +
                "copy saa/Configuration/Sample.xcconfig.example → Debug.xcconfig " +
                "and fill in your Supabase anon key."
            )
        }
        return key
    }()

    // MARK: - Private Helpers

    private static func value(for key: String) -> String? {
        guard let dict = Bundle.main.infoDictionary,
              let raw = dict[key] as? String,
              !raw.isEmpty,
              !raw.hasPrefix("$(") else {   // Guard against unexpanded xcconfig vars
            return nil
        }
        return raw
    }
}
