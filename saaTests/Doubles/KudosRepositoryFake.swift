import Foundation
@testable import saa

// MARK: - KudosRepositoryFake
//
// Configurable in-memory fake implementing `KudosRepositoryProtocol`.
// Per-call behavior (success / error), call counter.
//
// @unchecked Sendable: test doubles mutate properties from the test thread
// without synchronisation — intentional for ergonomics; never used in
// production code. Mirrors the convention from AwardsRepositoryFake.

final class KudosRepositoryFake: KudosRepositoryProtocol, @unchecked Sendable {

    enum HighlightBehavior {
        case success([Kudos])
        case error(KudosError)
    }

    enum FeedBehavior {
        case success([Kudos])
        case error(KudosError)
    }

    enum HashtagsBehavior {
        case success([Hashtag])
        case error(KudosError)
    }

    enum DepartmentsBehavior {
        case success([Department])
        case error(KudosError)
    }

    enum StatsBehavior {
        case success(UserStats)
        case error(KudosError)
    }

    enum RecipientsBehavior {
        case success([KudosAuthor])
        case error(KudosError)
    }

    enum EligibleRecipientsBehavior {
        case success([ProfileSummary])
        case error(KudosError)
    }

    enum BonusBehavior {
        case success(EventBonus?)
        case error(KudosError)
    }

    enum LikeBehavior {
        case success(Bool)
        case error(KudosError)
    }

    enum UnlikeBehavior {
        case success(Bool)
        case error(KudosError)
    }

    enum CreateKudoBehavior {
        case success(Kudos)
        case error(KudosError)
    }

    // MARK: - Per-method behaviors

    var highlightBehavior: HighlightBehavior = .success([])
    var feedBehavior: FeedBehavior = .success([])
    var hashtagsBehavior: HashtagsBehavior = .success([])
    var departmentsBehavior: DepartmentsBehavior = .success([])
    var statsBehavior: StatsBehavior = .success(.zero)
    var recipientsBehavior: RecipientsBehavior = .success([])
    var eligibleRecipientsBehavior: EligibleRecipientsBehavior = .success([])
    var bonusBehavior: BonusBehavior = .success(nil)
    var likeBehavior: LikeBehavior = .success(true)
    var unlikeBehavior: UnlikeBehavior = .success(false)
    var createKudoBehavior: CreateKudoBehavior = .error(.createDenied)  // safe default — must be set explicitly

    // MARK: - Page-indexed feed responses (for pagination testing)
    //
    // `feedPagesByPageIndex` maps page numbers to arrays of kudos. When set,
    // `fetchKudosFeed` returns `feedPagesByPageIndex[page] ?? []` instead of
    // consulting `feedBehavior`. This allows tests to seed deterministic paged
    // responses without complicated behavior setup.
    //
    // `feedFetchError` overrides all behavior: when non-nil, `fetchKudosFeed`
    // throws it immediately, regardless of `feedBehavior` or page mapping.
    //
    // Backwards-compatible: existing tests that do NOT set these fields get
    // the prior behavior (empty dictionary → default `[]` on any page fetch).
    var feedPagesByPageIndex: [Int: [Kudos]] = [:]
    var feedFetchError: Error?

    // MARK: - Call counters

    private(set) var fetchHighlightCalls = 0
    private(set) var fetchFeedCalls = 0
    private(set) var fetchHashtagsCalls = 0
    private(set) var fetchDepartmentsCalls = 0
    private(set) var fetchStatsCalls = 0
    private(set) var fetchRecipientsCalls = 0
    private(set) var fetchEligibleRecipientsCalls = 0
    private(set) var fetchBonusCalls = 0
    private(set) var likeCalls = 0
    private(set) var unlikeCalls = 0
    private(set) var createKudoCalls = 0
    private(set) var currentUserIdCalls = 0

    // MARK: - Last-arg recording

    var lastHighlightFilter: KudosFilter?
    var lastFeedFilter: KudosFilter?
    var lastFeedPage: Int?
    var lastFeedPageSize: Int?
    var lastLikeKudosId: KudosID?
    var lastLikeMultiplier: Int?
    var lastUnlikeKudosId: KudosID?
    var lastBonusNow: Date?
    var lastRecipientLimit: Int?
    var lastCreateKudoRequest: CreateKudoRequest?

    // MARK: - Current user simulation

    var _currentUserId: UUID? = nil

    // MARK: - Attachment URL resolution (configurable for testing)

    /// Optional closure to customize attachment URL resolution per path.
    /// When set, called instead of the default passthrough behavior.
    /// Useful for testing partial failure scenarios.
    var attachmentURLResolver: ((String) -> URL?)? = nil

    // MARK: - Protocol conformance

    func fetchHighlightKudos(filter: KudosFilter) async throws -> [Kudos] {
        fetchHighlightCalls += 1
        lastHighlightFilter = filter
        switch highlightBehavior {
        case .success(let kudos): return kudos
        case .error(let error): throw error
        }
    }

    func fetchKudosFeed(filter: KudosFilter, page: Int, pageSize: Int) async throws -> [Kudos] {
        fetchFeedCalls += 1
        lastFeedFilter = filter
        lastFeedPage = page
        lastFeedPageSize = pageSize

        // If feedFetchError is set, throw immediately (overrides all behavior).
        if let error = feedFetchError {
            throw error
        }

        // If feedPagesByPageIndex is populated, use page-indexed response.
        if !feedPagesByPageIndex.isEmpty {
            return feedPagesByPageIndex[page] ?? []
        }

        // Else fall back to the legacy feedBehavior.
        switch feedBehavior {
        case .success(let kudos): return kudos
        case .error(let error): throw error
        }
    }

    func fetchHashtags() async throws -> [Hashtag] {
        fetchHashtagsCalls += 1
        switch hashtagsBehavior {
        case .success(let hashtags): return hashtags
        case .error(let error): throw error
        }
    }

    func fetchDepartments() async throws -> [Department] {
        fetchDepartmentsCalls += 1
        switch departmentsBehavior {
        case .success(let departments): return departments
        case .error(let error): throw error
        }
    }

    func fetchMyStats() async throws -> UserStats {
        fetchStatsCalls += 1
        switch statsBehavior {
        case .success(let stats): return stats
        case .error(let error): throw error
        }
    }

    func fetchTopGiftRecipients(limit: Int) async throws -> [KudosAuthor] {
        fetchRecipientsCalls += 1
        lastRecipientLimit = limit
        switch recipientsBehavior {
        case .success(let authors): return authors
        case .error(let error): throw error
        }
    }

    func fetchEligibleRecipients() async throws -> [ProfileSummary] {
        fetchEligibleRecipientsCalls += 1
        switch eligibleRecipientsBehavior {
        case .success(let profiles): return profiles
        case .error(let error): throw error
        }
    }

    func fetchActiveEventBonus(now: Date) async throws -> EventBonus? {
        fetchBonusCalls += 1
        lastBonusNow = now
        switch bonusBehavior {
        case .success(let bonus): return bonus
        case .error(let error): throw error
        }
    }

    func likeKudos(kudosId: KudosID, multiplier: Int) async throws -> Bool {
        likeCalls += 1
        lastLikeKudosId = kudosId
        lastLikeMultiplier = multiplier
        switch likeBehavior {
        case .success(let result): return result
        case .error(let error): throw error
        }
    }

    func unlikeKudos(kudosId: KudosID) async throws -> Bool {
        unlikeCalls += 1
        lastUnlikeKudosId = kudosId
        switch unlikeBehavior {
        case .success(let result): return result
        case .error(let error): throw error
        }
    }

    func currentUserId() async -> UUID? {
        currentUserIdCalls += 1
        return _currentUserId
    }

    /// Passthrough — tests don't talk to Supabase Storage. Returns a parsed URL
    /// when one can be constructed from the path string, nil otherwise.
    /// Can be customized via `attachmentURLResolver` for testing partial failure.
    func attachmentImageURL(forStoragePath storagePath: String) async -> URL? {
        if let resolver = attachmentURLResolver {
            return resolver(storagePath)
        }
        return URL(string: storagePath)
    }

    func createKudo(_ request: CreateKudoRequest) async throws -> Kudos {
        createKudoCalls += 1
        lastCreateKudoRequest = request
        switch createKudoBehavior {
        case .success(let kudos): return kudos
        case .error(let error): throw error
        }
    }
}
