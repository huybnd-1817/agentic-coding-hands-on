import Foundation
import Supabase
@testable import saa

// MARK: - StubSupabase

/// Factory for an unreachable SupabaseClient used in unit tests.
/// Points at 127.0.0.1:1 — a loopback address where no service listens,
/// so any auth call fails immediately without DNS lookup or real network I/O.
enum StubSupabase {
    static func makeUnreachable() -> SupabaseClient {
        SupabaseClient(
            supabaseURL: URL(string: "http://127.0.0.1:1")!,
            supabaseKey: "test-anon-key"
        )
    }
}
