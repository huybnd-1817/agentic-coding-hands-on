import Foundation

// MARK: - KudosViewModel + All Feed pagination

extension KudosViewModel {

    /// Resets pagination state and fetches the first page of the unfiltered all-kudos feed.
    ///
    /// - Re-entrancy guard: no-ops immediately if a fetch is already in flight.
    /// - Always uses `KudosFilter()` (empty) — All Kudos is unfiltered per clarifications.
    /// - On success: transitions to `.loaded` (or `.endOfList` when fewer items than `pageSize`
    ///   are returned).
    /// - On failure: maps to `KudosError` and transitions to `.error(error)`.
    func loadAllFeedInitial() async {
        guard !isAllFeedFetchInFlight else { return }

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

    /// Fetches the next page of the all-kudos feed and appends it to `allFeed`.
    ///
    /// - Re-entrancy guard: no-ops when a fetch is already in flight OR when the
    ///   state is not `.loaded` (e.g. `.endOfList`, `.error`, `.idle`, `.loading`).
    ///   Only proceeds when `allFeedLoadState == .loaded`.
    /// - On success: deduplicates by `kudos.id` before appending (defensive — Supabase
    ///   page-index pagination is stable, but a concurrent refresh could produce
    ///   duplicate IDs on the overlap page). Transitions to `.endOfList` when the
    ///   returned page is smaller than `pageSize`.
    /// - On failure: decrements `allFeedPage` so the caller can retry via another
    ///   `loadAllFeedMore()` call once `allFeedLoadState` is reset by `loadAllFeedInitial()`.
    ///
    /// Recovery note: after an error the state is `.error`. The caller MUST invoke
    /// `loadAllFeedInitial()` to recover (retry from page 0); calling `loadAllFeedMore()`
    /// again will be a no-op because the guard requires `.loaded` state.
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
            // Deduplicate by id before appending — defensive against overlap on
            // concurrent refreshes. Supabase page-index pagination is stable, but
            // a simultaneous `loadAllFeedInitial()` (e.g. triggered by create-kudo)
            // could re-emit items already in `allFeed`.
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

    /// Synchronously resets all-feed state to idle (called on `.onDisappear` by the container).
    ///
    /// Does NOT cancel any in-flight fetch — the in-flight task will complete and
    /// write its results to `allFeed`/`allFeedLoadState`, which are then ignored
    /// by the already-dismissed view. This avoids a Task cancellation error path.
    func resetAllFeed() {
        allFeed = []
        allFeedPage = 0
        allFeedLoadState = .idle
        // `isAllFeedFetchInFlight` is intentionally left untouched — let the
        // in-flight fetch complete naturally and discard results.
    }
}
