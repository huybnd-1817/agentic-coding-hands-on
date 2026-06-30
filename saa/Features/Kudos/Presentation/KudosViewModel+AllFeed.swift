import Foundation

// MARK: - KudosViewModel + All Feed pagination

extension KudosViewModel {

    /// Resets pagination and fetches page 0 of the unfiltered all-kudos feed.
    /// Idempotent — re-entering All Kudos via a detail-pop must preserve the
    /// existing pages + scroll position. Pull-to-refresh (`refreshAllFeed`)
    /// is the explicit path for fresh data. Only `.idle` and `.error` entry
    /// states proceed; all others (already loaded / in-flight) skip.
    func loadAllFeedInitial() async {
        guard !isAllFeedFetchInFlight else { return }
        switch allFeedLoadState {
        case .idle, .error: break
        default: return
        }

        allFeedPage = 0
        allFeed = []
        allFeedLoadState = .loading
        isAllFeedFetchInFlight = true
        defer { isAllFeedFetchInFlight = false }

        do {
            let results = try await repository.fetchKudosFeed(
                filter: KudosFilter(),
                page: 0,
                pageSize: allFeedPageSize
            )
            allFeed = results
            allFeedLoadState = results.count < allFeedPageSize ? .endOfList : .loaded
        } catch let error as KudosError {
            allFeedLoadState = .error(error)
        } catch {
            allFeedLoadState = .error(.unknown(underlying: error.localizedDescription))
        }
    }

    /// Fetches the next page and appends to `allFeed`. Only proceeds when
    /// `allFeedLoadState == .loaded`. Deduplicates by id (defensive against
    /// concurrent refresh overlap). On error, decrements `allFeedPage` and
    /// transitions to `.error` — caller must invoke `loadAllFeedInitial()`
    /// to recover.
    func loadAllFeedMore() async {
        guard !isAllFeedFetchInFlight, allFeedLoadState == .loaded else { return }

        allFeedPage += 1
        allFeedLoadState = .loadingMore
        isAllFeedFetchInFlight = true
        defer { isAllFeedFetchInFlight = false }

        do {
            let results = try await repository.fetchKudosFeed(
                filter: KudosFilter(),
                page: allFeedPage,
                pageSize: allFeedPageSize
            )
            // Defensive dedupe against concurrent refresh overlap.
            let existingIds = Set(allFeed.map(\.id))
            let newItems = results.filter { !existingIds.contains($0.id) }
            allFeed.append(contentsOf: newItems)
            allFeedLoadState = results.count < allFeedPageSize ? .endOfList : .loaded
        } catch let error as KudosError {
            allFeedPage -= 1  // Allow retry after recovery via loadAllFeedInitial
            allFeedLoadState = .error(error)
        } catch {
            allFeedPage -= 1
            allFeedLoadState = .error(.unknown(underlying: error.localizedDescription))
        }
    }

    /// Pull-to-refresh: refetches page 0 without clearing `allFeed` first, so
    /// the existing list stays visible behind SwiftUI's spinner and replaces
    /// atomically when the new page arrives (no empty-list flash). Keeps the
    /// existing list on failure.
    func refreshAllFeed() async {
        guard !isAllFeedFetchInFlight else { return }
        isAllFeedFetchInFlight = true
        defer { isAllFeedFetchInFlight = false }

        do {
            let results = try await repository.fetchKudosFeed(
                filter: KudosFilter(),
                page: 0,
                pageSize: allFeedPageSize
            )
            allFeed = results
            allFeedPage = 0
            allFeedLoadState = results.count < allFeedPageSize ? .endOfList : .loaded
        } catch let error as KudosError {
            allFeedLoadState = .error(error)
        } catch {
            allFeedLoadState = .error(.unknown(underlying: error.localizedDescription))
        }
    }

    /// Resets state to idle without cancelling any in-flight fetch — that
    /// avoids a Task cancellation error path; the in-flight task completes
    /// and writes to state which the dismissed view ignores.
    func resetAllFeed() {
        allFeed = []
        allFeedPage = 0
        allFeedLoadState = .idle
    }
}
