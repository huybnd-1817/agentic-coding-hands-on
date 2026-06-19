import Foundation

// MARK: - HashtagID

typealias HashtagID = UUID

// MARK: - Hashtag

/// A topic label associated with one or more kudos posts.
///
/// `tag` is stored with its leading `#` (e.g. `"#Teamwork"`) so views render
/// it verbatim without string manipulation. Filtering by hashtag uses `id`
/// so tag renames do not break existing filter state.
struct Hashtag: Identifiable, Hashable, Sendable {
    let id: HashtagID
    /// Display label including the leading `#` (e.g. `"#Teamwork"`).
    let tag: String
}
