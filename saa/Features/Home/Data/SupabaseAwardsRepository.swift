import Foundation
import Supabase

// MARK: - SupabaseAwardsRepository

/// Data-layer implementation of `AwardsRepositoryProtocol` backed by the
/// Supabase Postgrest client.
///
/// All SDK calls (`client.from(...)`) are confined to this file. The default
/// `SupabaseClient` is resolved inside the init body so `SupabaseClientProvider.shared`
/// is touched only after the static let is safe to read.
struct SupabaseAwardsRepository: AwardsRepositoryProtocol {

    // MARK: - Properties

    let client: SupabaseClient

    // MARK: - Init

    init(client: SupabaseClient? = nil) {
        self.client = client ?? SupabaseClientProvider.shared
    }
}

// MARK: - AwardsRepositoryProtocol

extension SupabaseAwardsRepository {

    /// Fetches all awards from `public.awards`, sorted by the server.
    ///
    /// RLS allows `select` for the `authenticated` role only; an expired JWT
    /// surfaces as 401 and is mapped to `.unauthorized`.
    func fetchAwards() async throws -> [Award] {
        do {
            let dtos: [AwardDTO] = try await client
                .from("awards")
                .select()
                .order("sort_order", ascending: true)
                .execute()
                .value
            return dtos.map(AwardMapper.toDomain)
        } catch {
            throw AwardsErrorMapper.from(error)
        }
    }
}
