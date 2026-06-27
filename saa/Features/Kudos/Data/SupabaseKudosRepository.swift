import Foundation
import Supabase

// MARK: - SupabaseKudosRepository

/// Data-layer implementation of `KudosRepositoryProtocol` backed by Supabase PostgREST.
///
/// All SDK calls are confined to this file and its extensions. The `client`
/// property is resolved from `SupabaseClientProvider.shared` when no explicit
/// client is injected, matching the pattern in `SupabaseAwardsRepository`.
///
/// `currentUserId` is read from `client.auth.currentUser?.id` before each
/// batch query and threaded into `KudosMapper` for anonymous masking — it is
/// never stored as mutable state to preserve `Sendable` safety.
final class SupabaseKudosRepository: KudosRepositoryProtocol, Sendable {

    // MARK: - Dependencies

    let client: SupabaseClient

    // MARK: - Init

    init(client: SupabaseClient? = nil) {
        self.client = client ?? SupabaseClientProvider.shared
    }

    // MARK: - currentUserId

    func currentUserId() async -> UUID? {
        client.auth.currentUser?.id
    }
}

// MARK: - Read operations

extension SupabaseKudosRepository {

    func fetchHighlightKudos(filter: KudosFilter) async throws -> [Kudos] {
        do {
            let userId = await currentUserId()
            // Filters must be applied BEFORE ordering/limits (PostgrestFilterBuilder
            // → PostgrestTransformBuilder is one-way in the Supabase Swift SDK).
            let baseQuery = client
                .from("kudos")
                .select(kudosSelectClause(for: filter))
                .eq("status", value: "active")
                .is("deleted_at", value: nil)
            let filtered = applyFilter(filter, to: baseQuery)
            // Sort client-side: PostgREST can't ORDER BY a nested aggregate alias.
            // Top-5 by hearts is small bounded N (carousel limit), so client sort is cheap.
            // Fetch up to 50 recent rows, sort by heartCount descending, then take the top 5.
            let dtos: [KudosDTO] = try await filtered
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value
            let topDtos = Array(dtos.sorted { $0.heartCount > $1.heartCount }.prefix(5))
            return try await mapBatch(topDtos, currentUserId: userId)
        } catch {
            throw KudosErrorMapper.from(error)
        }
    }

    func fetchKudosFeed(filter: KudosFilter, page: Int, pageSize: Int) async throws -> [Kudos] {
        do {
            let userId = await currentUserId()
            let from = page * pageSize
            let to = from + pageSize - 1
            // Filters must be applied before ordering/range transforms.
            let baseQuery = client
                .from("kudos")
                .select(kudosSelectClause(for: filter))
                .eq("status", value: "active")
                .is("deleted_at", value: nil)
            let filtered = applyFilter(filter, to: baseQuery)
            let dtos: [KudosDTO] = try await filtered
                .order("created_at", ascending: false)
                .range(from: from, to: to)
                .execute()
                .value
            return try await mapBatch(dtos, currentUserId: userId)
        } catch {
            throw KudosErrorMapper.from(error)
        }
    }

    func fetchHashtags() async throws -> [Hashtag] {
        do {
            let dtos: [HashtagDTO] = try await client
                .from("hashtags")
                .select()
                .order("tag", ascending: true)
                .execute()
                .value
            return dtos.map(HashtagMapper.from)
        } catch {
            throw KudosErrorMapper.from(error)
        }
    }

    func fetchDepartments() async throws -> [Department] {
        do {
            let dtos: [DepartmentDTO] = try await client
                .from("departments")
                .select()
                .order("name", ascending: true)
                .execute()
                .value
            return dtos.map(DepartmentMapper.from)
        } catch {
            throw KudosErrorMapper.from(error)
        }
    }

    func fetchMyStats() async throws -> UserStats {
        guard let userId = await currentUserId() else {
            throw KudosError.notAuthenticated
        }
        do {
            let dto: UserStatsDTO = try await client
                .from("user_stats")
                .select()
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value
            return UserStatsMapper.from(dto)
        } catch {
            throw KudosErrorMapper.from(error)
        }
    }

    func fetchTopGiftRecipients(limit: Int) async throws -> [KudosAuthor] {
        // Out of scope: replaced when reward_recipients table lands (see plan deferred).
        return []
    }

    func fetchEligibleRecipients() async throws -> [ProfileSummary] {
        guard let selfId = await currentUserId() else {
            throw KudosError.notAuthenticated
        }
        do {
            // Lightweight profile fetch: only columns that exist on `public.profiles`
            // (id, name, avatar_url, department_id). The schema has no
            // `employee_code` column — selecting it returns PGRST204 and
            // empties the dropdown.
            struct ProfileRow: Decodable, Sendable {
                let id: UUID
                let name: String?
                let avatar_url: String?
                let department_id: UUID?
            }
            let rows: [ProfileRow] = try await client
                .from("profiles")
                .select("id, name, avatar_url, department_id")
                .neq("id", value: selfId.uuidString)
                .order("name", ascending: true)
                .execute()
                .value
            return rows.map { row in
                ProfileSummary(
                    id: row.id,
                    displayName: row.name ?? "",
                    employeeCode: nil,
                    avatarURL: row.avatar_url.flatMap { URL(string: $0) },
                    department: nil
                )
            }
        } catch {
            throw KudosErrorMapper.from(error)
        }
    }

    func fetchActiveEventBonus(now: Date) async throws -> EventBonus? {
        do {
            // DB-level window filter: WHERE now BETWEEN starts_at AND ends_at
            let nowISO = ISO8601DateFormatter().string(from: now)
            let dtos: [EventBonusDTO] = try await client
                .from("event_bonuses")
                .select()
                .lte("starts_at", value: nowISO)
                .gte("ends_at", value: nowISO)
                .order("starts_at", ascending: false)
                .limit(1)
                .execute()
                .value
            return dtos.first.map(EventBonusMapper.from)
        } catch {
            throw KudosErrorMapper.from(error)
        }
    }
}

// MARK: - Write operations

extension SupabaseKudosRepository {

    func likeKudos(kudosId: KudosID, multiplier: Int) async throws -> Bool {
        guard let userId = await currentUserId() else {
            throw KudosError.notAuthenticated
        }
        do {
            // INSERT into kudos_reactions. RLS policy rejects own-kudos (42501)
            // and unique constraint rejects duplicates (23505).
            try await client
                .from("kudos_reactions")
                .insert([
                    "kudos_id": kudosId.uuidString,
                    "user_id": userId.uuidString,
                    "multiplier": String(multiplier)
                ])
                .execute()
            return true
        } catch {
            throw KudosErrorMapper.from(error)
        }
    }

    func unlikeKudos(kudosId: KudosID) async throws -> Bool {
        guard let userId = await currentUserId() else {
            throw KudosError.notAuthenticated
        }
        do {
            try await client
                .from("kudos_reactions")
                .delete()
                .eq("kudos_id", value: kudosId.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
            return false
        } catch {
            throw KudosErrorMapper.from(error)
        }
    }

    func createKudo(_ request: CreateKudoRequest) async throws -> Kudos {
        // Step 1: Insert the kudos row and receive the generated id.
        let insertedKudosId: UUID
        do {
            let kudosBody = CreateKudoMapper.kudosDTO(from: request)
            let response: [KudosInsertResponseDTO] = try await client
                .from("kudos")
                .insert(kudosBody)
                .select("id")
                .execute()
                .value
            guard let first = response.first else {
                throw KudosError.createDenied
            }
            insertedKudosId = first.id
        } catch {
            throw KudosErrorMapper.from(error)
        }

        // Steps 2 & 3 can fail after the kudos row is committed.
        // On any failure: attempt best-effort rollback then re-throw.
        do {
            // Step 2: Batch insert kudos_hashtags.
            let hashtagDTOs = CreateKudoMapper.hashtagDTOs(kudosId: insertedKudosId, from: request)
            if !hashtagDTOs.isEmpty {
                try await client
                    .from("kudos_hashtags")
                    .insert(hashtagDTOs)
                    .execute()
            }

            // Step 3: Batch insert kudos_attachments (skip when no attachments).
            // Re-assign sort_order by array position (uploader sets 0 as placeholder).
            if !request.attachments.isEmpty {
                let attachmentDTOs = request.attachments.enumerated().map { idx, att in
                    CreateKudoAttachmentDTO(
                        kudos_id: insertedKudosId.uuidString,
                        storage_path: att.storagePath,
                        sort_order: idx,
                        content_type: att.contentType,
                        byte_size: att.byteSize
                    )
                }
                try await client
                    .from("kudos_attachments")
                    .insert(attachmentDTOs)
                    .execute()
            }
        } catch {
            // Best-effort rollback: remove uploaded storage objects first, then delete the
            // orphaned kudos row. Order matters: the kudos DELETE (with cascade) would remove
            // kudos_attachments DB rows, but the Storage objects must be removed explicitly.
            let originalError = error

            // 1. Remove Storage objects for any attachments that were already uploaded.
            let storagePaths = request.attachments.map(\.storagePath)
            if !storagePaths.isEmpty {
                do {
                    try await client.storage
                        .from("kudos-images")
                        .remove(paths: storagePaths)
                } catch {
                    #if DEBUG
                    print("[Kudos] createKudo storage cleanup failed for \(storagePaths): \(error)")
                    #endif
                    // Best-effort: continue to DB rollback even if Storage delete fails.
                }
            }

            // 2. Delete the orphaned kudos row (cascade removes kudos_hashtags / kudos_attachments).
            do {
                try await client
                    .from("kudos")
                    .delete()
                    .eq("id", value: insertedKudosId.uuidString)
                    .execute()
            } catch {
                #if DEBUG
                print("[Kudos] createKudo rollback failed for id \(insertedKudosId): \(error)")
                #endif
            }
            throw KudosErrorMapper.from(originalError)
        }

        // Step 4: Fetch the full kudos entity with all joins and return it.
        do {
            let userId = await currentUserId()
            let dtos: [KudosDTO] = try await client
                .from("kudos")
                .select(kudosSelectClause(for: KudosFilter()))
                .eq("id", value: insertedKudosId.uuidString)
                .limit(1)
                .execute()
                .value
            guard let dto = dtos.first else {
                throw KudosError.unknown(underlying: "Created kudos not found after insert")
            }
            // Resolve liked state (always false for a brand-new kudos).
            return KudosMapper.from(dto, currentUserId: userId, isLikedByMe: false)
        } catch {
            throw KudosErrorMapper.from(error)
        }
    }
}

// MARK: - Private helpers

private extension SupabaseKudosRepository {

    /// Supabase nested-select string for the full kudos shape with joins.
    ///
    /// Filter-aware embedding: when a filter is active, the corresponding
    /// embed is upgraded to `!inner` so PostgREST excludes rows that don't
    /// match (rather than nullifying the embed and returning the outer row
    /// anyway, which produced the "BOD shows blank recipient" and
    /// "filtered list contains non-matching kudos" bugs).
    ///
    /// Aggregate strategy: `reactions:kudos_reactions(count)` returns an array
    /// with one element `{"count": N}` — decoded into `KudosDTO.reactions`.
    /// `KudosDTO.heartCount` takes `.first?.count ?? 0`.
    func kudosSelectClause(for filter: KudosFilter) -> String {
        // user_stats nested join returns a JSON object, not a scalar — alias as "user_stats"
        // so it decodes into KudosProfileUserStatsDTO (field name must match CodingKey).
        let recipientJoinHint = (filter.departmentId != nil) ? "!inner" : ""
        let hashtagJoinHint = (filter.hashtagId != nil) ? "!inner" : ""
        return """
        *,
        sender:profiles!sender_id(id, name, avatar_url, email, department_id, user_stats(kudos_received_count)),
        recipient:profiles!recipient_id\(recipientJoinHint)(id, name, avatar_url, email, department_id, user_stats(kudos_received_count)),
        kudos_hashtags\(hashtagJoinHint)(hashtag:hashtags(id, tag)),
        kudos_attachments(id, storage_path, sort_order, content_type, byte_size),
        reactions:kudos_reactions(count)
        """
    }

    /// Applies hashtag and department filters to a PostgREST query builder.
    func applyFilter(
        _ filter: KudosFilter,
        to query: PostgrestFilterBuilder
    ) -> PostgrestFilterBuilder {
        var q = query
        if let hashtagId = filter.hashtagId {
            // Filter kudos that have this hashtag via the join table.
            q = q.eq("kudos_hashtags.hashtag_id", value: hashtagId.uuidString)
        }
        if let departmentId = filter.departmentId {
            // Filter by recipient's department_id on the joined recipient profile.
            q = q.eq("recipient.department_id", value: departmentId.uuidString)
        }
        return q
    }

    /// Resolves `isLikedByMe` for a batch of DTOs by fetching reaction user_ids
    /// for the batch in a single query, then maps each DTO to a `Kudos` entity.
    func mapBatch(_ dtos: [KudosDTO], currentUserId: UUID?) async throws -> [Kudos] {
        guard !dtos.isEmpty else { return [] }

        // Resolve liked state: fetch all reactions for this batch where user = me.
        var likedKudosIds: Set<UUID> = []
        if let userId = currentUserId {
            // Single round-trip: fetch only this user's reactions for the batch.
            struct ReactionRow: Decodable { let kudos_id: UUID }
            let rows: [ReactionRow] = (try? await client
                .from("kudos_reactions")
                .select("kudos_id")
                .in("kudos_id", values: dtos.map(\.id.uuidString))
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value) ?? []
            likedKudosIds = Set(rows.map(\.kudos_id))
        }

        return dtos.map { dto in
            KudosMapper.from(
                dto,
                currentUserId: currentUserId,
                isLikedByMe: likedKudosIds.contains(dto.id)
            )
        }
    }
}
