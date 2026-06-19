import Foundation

// MARK: - KudosToast

/// Discrete toast messages surfaced by `KudosViewModel` to inform the user of
/// brief, transient outcomes (copy-link success, feature stubs, and like failures).
///
/// `messageKey` returns an i18n catalog key so `Text(LocalizedStringKey(toast.messageKey))`
/// honours the in-app language setting rather than the system locale.
enum KudosToast: Equatable, Sendable {

    /// Emitted when the share URL for a kudos is copied to the clipboard.
    case linkCopied

    /// Emitted when the user taps a feature that is not yet implemented (e.g. Secret Box open flow).
    case comingSoon

    /// Emitted when a like or unlike network call fails and the optimistic update is rolled back.
    case likeFailed

    // MARK: - Localisation

    /// i18n catalog key for the toast message.
    ///
    /// Pass to `Text(LocalizedStringKey(toast.messageKey))` or a toast overlay component.
    var messageKey: String {
        switch self {
        case .linkCopied:  return "kudos.toast.linkCopied"
        case .comingSoon:  return "kudos.toast.comingSoon"
        case .likeFailed:  return "kudos.toast.likeFailed"
        }
    }
}
