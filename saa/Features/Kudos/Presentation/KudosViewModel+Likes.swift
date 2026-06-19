import Foundation

// MARK: - KudosViewModel + Like toggling

extension KudosViewModel {

    /// Toggles the heart reaction on a kudos post with optimistic UI and rollback on failure.
    ///
    /// Optimistic path:
    ///   1. Snapshot the prior `Kudos` value for rollback.
    ///   2. Mutate `highlights` and `feed` in-place (flip `isLikedByMe`, adjust `heartCount`).
    ///   3. Await `ToggleKudosReactionUseCase.execute(...)`.
    ///   4. On success: no-op (the view already shows the correct state).
    ///   5. On failure: restore prior values and emit `.likeFailed` toast.
    ///
    /// A per-kudos in-flight guard (`likeInFlight`) prevents concurrent double-taps on the
    /// same card from sending duplicate network requests.
    func toggleLike(_ id: KudosID) async {
        guard !likeInFlight.contains(id) else { return }

        // Find current kudos in either array.
        guard let prior = findKudos(id: id) else { return }
        guard prior.canLike else { return }

        likeInFlight.insert(id)
        defer { likeInFlight.remove(id) }

        // Optimistic update — flip state immediately.
        let optimisticLiked = !prior.isLikedByMe
        let delta = optimisticLiked ? 1 : -1
        updateKudos(id: id, isLikedByMe: optimisticLiked, heartCountDelta: delta)

        do {
            _ = try await toggleReactionUseCase.execute(
                kudosId: id,
                currentlyLiked: prior.isLikedByMe
            )
            // Server confirmed — nothing more to do; UI already reflects the new state.
        } catch {
            // Rollback to prior values.
            updateKudos(
                id: id,
                isLikedByMe: prior.isLikedByMe,
                heartCountDelta: -delta
            )
            emitToast(.likeFailed)
        }
    }

    // MARK: - Internal helpers (called from KudosViewModel.swift via same-module access)

    /// Returns the `Kudos` with the given id, searching highlights first then feed.
    func findKudos(id: KudosID) -> Kudos? {
        highlights.first(where: { $0.id == id })
            ?? feed.first(where: { $0.id == id })
    }

    /// Mutates `isLikedByMe` and adjusts `heartCount` by `heartCountDelta` for the
    /// kudos matching `id` in both `highlights` and `feed`.
    ///
    /// Swift structs are value types; we must replace the element in the array.
    /// Using `map` keeps the array-level assignment on MainActor where it belongs.
    func updateKudos(id: KudosID, isLikedByMe: Bool, heartCountDelta: Int) {
        highlights = highlights.map { kudos in
            guard kudos.id == id else { return kudos }
            return patched(kudos, isLikedByMe: isLikedByMe, heartCountDelta: heartCountDelta)
        }
        feed = feed.map { kudos in
            guard kudos.id == id else { return kudos }
            return patched(kudos, isLikedByMe: isLikedByMe, heartCountDelta: heartCountDelta)
        }
    }

    // MARK: - Private

    /// Creates a copy of `kudos` with updated `isLikedByMe` and adjusted `heartCount`.
    ///
    /// `Kudos` is a struct with `let` fields (all immutable). We must reconstruct it.
    private func patched(_ kudos: Kudos, isLikedByMe: Bool, heartCountDelta: Int) -> Kudos {
        Kudos(
            id: kudos.id,
            sender: kudos.sender,
            recipient: kudos.recipient,
            title: kudos.title,
            message: kudos.message,
            isAnonymous: kudos.isAnonymous,
            anonymousNickname: kudos.anonymousNickname,
            hashtags: kudos.hashtags,
            photoURL: kudos.photoURL,
            heartCount: max(0, kudos.heartCount + heartCountDelta),
            isLikedByMe: isLikedByMe,
            canLike: kudos.canLike,
            shareURL: kudos.shareURL,
            createdAt: kudos.createdAt
        )
    }

}
