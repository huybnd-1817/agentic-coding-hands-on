import Foundation

// MARK: - CreateKudoFormState

/// Value-type snapshot of all mutable form fields.
///
/// `CreateKudoViewModel` captures an initial snapshot on init and compares
/// the current field values against it to compute `isDirty`.
///
/// Equatable conformance is structural so `==` detects any field change.
struct CreateKudoFormState: Equatable, Sendable {

    var recipientId: UUID?
    var title: String
    var message: String
    var selectedHashtagIds: [HashtagID]
    /// Draft IDs only — upload state is ephemeral and not part of dirty tracking.
    var imageDraftIds: [UUID]
    var isAnonymous: Bool
    var anonymousNickname: String

    // MARK: - Default (empty form)

    static let empty = CreateKudoFormState(
        recipientId: nil,
        title: "",
        message: "",
        selectedHashtagIds: [],
        imageDraftIds: [],
        isAnonymous: false,
        anonymousNickname: ""
    )
}
