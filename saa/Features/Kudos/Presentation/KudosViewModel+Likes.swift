import Foundation

// MARK: - KudosViewModel + Like toggling

extension KudosViewModel {

    /// Optimistic toggle with rollback on failure. Per-kudos in-flight guard
    /// blocks duplicate network calls from concurrent double-taps.
    func toggleLike(_ id: KudosID) async {
        guard !likeInFlight.contains(id) else { return }
        guard let prior = findKudos(id: id), prior.canLike else { return }

        likeInFlight.insert(id)
        defer { likeInFlight.remove(id) }

        let optimisticLiked = !prior.isLikedByMe
        let delta = optimisticLiked ? 1 : -1
        updateKudos(id: id, isLikedByMe: optimisticLiked, heartCountDelta: delta)

        do {
            _ = try await toggleReactionUseCase.execute(
                kudosId: id,
                currentlyLiked: prior.isLikedByMe
            )
        } catch {
            updateKudos(id: id, isLikedByMe: prior.isLikedByMe, heartCountDelta: -delta)
            emitToast(.likeFailed)
        }
    }

    // MARK: - Internal helpers (called from KudosViewModel.swift via same-module access)

    /// Returns the `Kudos` with the given id, searching highlights, feed, then allFeed.
    func findKudos(id: KudosID) -> Kudos? {
        highlights.first(where: { $0.id == id })
            ?? feed.first(where: { $0.id == id })
            ?? allFeed.first(where: { $0.id == id })
    }

    /// Mutates `isLikedByMe` and adjusts `heartCount` by `heartCountDelta` for the
    /// kudos matching `id` in `highlights`, `feed`, and `allFeed`.
    ///
    /// `allFeed` is walked so a like toggle on the All Kudos screen propagates
    /// to the Kudos tab preview and vice-versa (clarifications.md §like-state-sync).
    func updateKudos(id: KudosID, isLikedByMe: Bool, heartCountDelta: Int) {
        func patch(_ kudos: Kudos) -> Kudos {
            guard kudos.id == id else { return kudos }
            return patched(kudos, isLikedByMe: isLikedByMe, heartCountDelta: heartCountDelta)
        }
        highlights = highlights.map(patch)
        feed = feed.map(patch)
        allFeed = allFeed.map(patch)
    }

    // MARK: - Private

    /// Reconstructs `Kudos` (all-let struct) with updated like fields.
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
            attachments: kudos.attachments,
            heartCount: max(0, kudos.heartCount + heartCountDelta),
            isLikedByMe: isLikedByMe,
            canLike: kudos.canLike,
            shareURL: kudos.shareURL,
            createdAt: kudos.createdAt
        )
    }

}
