import Foundation
import Supabase

// MARK: - SupabaseKudosRepository

/// Supabase PostgREST implementation. All SDK calls are confined to this file
/// and its extensions. `currentUserId` is read on demand and threaded through
/// `KudosMapper` — never stored, to keep this type `Sendable`.
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

    // MARK: - Attachment URL resolution

    /// Three input shapes (legacy backfill from `photo_url`):
    /// - fully-qualified HTTPS → returned as-is
    /// - `kudos-images/{path}` → prefix stripped then signed
    /// - `{path}` → signed directly
    /// Signed URLs expire in 1 hour.
    func attachmentImageURL(forStoragePath storagePath: String) async -> URL? {
        if let url = URL(string: storagePath),
           let scheme = url.scheme,
           scheme == "http" || scheme == "https" {
            return url
        }
        let bucket = SupabaseStorageImageUploader.bucketName  // "kudos-images"
        let prefix = "\(bucket)/"
        let path = storagePath.hasPrefix(prefix)
            ? String(storagePath.dropFirst(prefix.count))
            : storagePath
        do {
            return try await client.storage
                .from(bucket)
                .createSignedURL(path: path, expiresIn: 3600)
        } catch {
            return nil
        }
    }
}

// MARK: - Read operations

extension SupabaseKudosRepository {

    func fetchHighlightKudos(filter: KudosFilter) async throws -> [Kudos] {
        do {
            let userId = await currentUserId()
            // Filters must precede ordering/limits (Filter → Transform builder is one-way).
            let baseQuery = client
                .from("kudos")
                .select(kudosSelectClause(for: filter))
                .eq("status", value: "active")
                .is("deleted_at", value: nil)
            let filtered = applyFilter(filter, to: baseQuery)
            // Client-side sort: PostgREST can't ORDER BY a nested aggregate alias.
            // Top-5 of 50 most recent — small bounded N, cheap.
            let dtos: [KudosDTO] = try await filtered
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value
            let topDtos = Array(dtos.sorted { $0.heartCount > $1.heartCount }.prefix(5))
            let override = try await hashtagsOverride(for: topDtos, filter: filter)
            return try await mapBatch(topDtos, currentUserId: userId, hashtagsOverride: override)
        } catch {
            throw KudosErrorMapper.from(error)
        }
    }

    func fetchKudosFeed(filter: KudosFilter, page: Int, pageSize: Int) async throws -> [Kudos] {
        do {
            let userId = await currentUserId()
            let from = page * pageSize
            let to = from + pageSize - 1
            // Filters precede ordering/range (see fetchHighlightKudos).
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
            let override = try await hashtagsOverride(for: dtos, filter: filter)
            return try await mapBatch(dtos, currentUserId: userId, hashtagsOverride: override)
        } catch {
            throw KudosErrorMapper.from(error)
        }
    }

    /// Skip the override fetch when no hashtag filter is active — the embed
    /// is already complete in that case.
    private func hashtagsOverride(
        for dtos: [KudosDTO],
        filter: KudosFilter
    ) async throws -> [UUID: [Hashtag]]? {
        guard filter.hashtagId != nil, !dtos.isEmpty else { return nil }
        return try await fullHashtags(for: dtos.map(\.id))
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
            // `profiles` has no `employee_code` column — selecting it returns
            // PGRST204 and empties the dropdown.
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
            // RLS rejects own-kudos (42501); unique constraint rejects dupes (23505).
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
        // 1. Insert kudos row, capture generated id.
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

        // Steps 2 & 3 may fail after the kudos row is committed — rollback path below.
        do {
            // 2. Batch insert kudos_hashtags.
            let hashtagDTOs = CreateKudoMapper.hashtagDTOs(kudosId: insertedKudosId, from: request)
            if !hashtagDTOs.isEmpty {
                try await client
                    .from("kudos_hashtags")
                    .insert(hashtagDTOs)
                    .execute()
            }

            // 3. Batch insert kudos_attachments (sort_order = array position).
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
            // Best-effort rollback: Storage objects must be removed explicitly
            // (DB cascade only removes the attachments rows, not bucket files).
            let originalError = error

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
                }
            }

            // Cascade removes kudos_hashtags + kudos_attachments rows.
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

        // 4. Fetch with full joins and return.
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
            return KudosMapper.from(dto, currentUserId: userId, isLikedByMe: false)
        } catch {
            throw KudosErrorMapper.from(error)
        }
    }
}

// MARK: - Private helpers

private extension SupabaseKudosRepository {

    /// Filter-aware select. When a filter is active the corresponding embed
    /// is upgraded to `!inner` so PostgREST excludes non-matching rows (rather
    /// than nulling the embed and returning the outer row anyway, which caused
    /// the "BOD shows blank recipient" / "filtered list contains non-matching
    /// kudos" bugs).
    func kudosSelectClause(for filter: KudosFilter) -> String {
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

    func applyFilter(
        _ filter: KudosFilter,
        to query: PostgrestFilterBuilder
    ) -> PostgrestFilterBuilder {
        var q = query
        if let hashtagId = filter.hashtagId {
            q = q.eq("kudos_hashtags.hashtag_id", value: hashtagId.uuidString)
        }
        if let departmentId = filter.departmentId {
            q = q.eq("recipient.department_id", value: departmentId.uuidString)
        }
        return q
    }

    /// Resolves `isLikedByMe` for the batch in a single round-trip, then
    /// maps each DTO. `hashtagsOverride` is used in place of the embedded
    /// `kudos_hashtags` when a hashtag filter pruned the embed (see
    /// `fullHashtags(for:)`).
    func mapBatch(
        _ dtos: [KudosDTO],
        currentUserId: UUID?,
        hashtagsOverride: [UUID: [Hashtag]]? = nil
    ) async throws -> [Kudos] {
        guard !dtos.isEmpty else { return [] }

        var likedKudosIds: Set<UUID> = []
        if let userId = currentUserId {
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
                isLikedByMe: likedKudosIds.contains(dto.id),
                hashtagsOverride: hashtagsOverride?[dto.id]
            )
        }
    }

    /// Fetches the full hashtag list in one round-trip to repair the embed
    /// pruned by an active hashtag filter (see `kudosSelectClause(for:)`).
    func fullHashtags(for kudosIds: [UUID]) async throws -> [UUID: [Hashtag]] {
        guard !kudosIds.isEmpty else { return [:] }
        struct Row: Decodable {
            let kudos_id: UUID
            let hashtag: HashtagDTO
        }
        let rows: [Row] = (try? await client
            .from("kudos_hashtags")
            .select("kudos_id, hashtag:hashtags(id, tag)")
            .in("kudos_id", values: kudosIds.map(\.uuidString))
            .execute()
            .value) ?? []
        var result: [UUID: [Hashtag]] = [:]
        for row in rows {
            result[row.kudos_id, default: []].append(HashtagMapper.from(row.hashtag))
        }
        return result
    }
}
