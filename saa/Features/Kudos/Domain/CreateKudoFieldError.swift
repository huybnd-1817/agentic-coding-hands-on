import Foundation

// MARK: - CreateKudoFieldError

/// Field-level validation errors returned by `CreateKudoValidator.validate(_:)`.
///
/// Each case maps to exactly one failed rule in the validation table (phase-05).
/// The UI layer uses these to highlight specific form fields.
enum CreateKudoFieldError: Equatable, Sendable {

    // MARK: Recipient

    /// No recipient has been selected.
    case recipientRequired

    /// The selected recipient is the same as the sender.
    case cannotSendToSelf

    // MARK: Title

    /// Title field is empty or whitespace-only after trimming.
    case titleRequired

    /// Title exceeds 100 characters after trimming.
    case titleTooLong

    // MARK: Message

    /// Message field is empty after trimming.
    case messageRequired

    /// Message contains only whitespace characters.
    case messageWhitespaceOnly

    /// Message exceeds 1 000 characters after trimming.
    case messageTooLong

    // MARK: Hashtags

    /// No hashtag has been selected (minimum 1 required).
    case hashtagsRequired

    /// More than 5 hashtags were selected.
    case hashtagsTooMany

    // MARK: Images

    /// More than 5 image drafts were attached.
    case imagesTooMany

    /// At least one image draft exceeds 5 MB.
    case imageTooLarge

    /// At least one image draft has an unsupported MIME type (not JPEG or PNG).
    case unsupportedImageType

    // MARK: Anonymous nickname

    /// `isAnonymous` is `true` but no nickname was provided or it is empty.
    case nicknameRequired

    /// Anonymous nickname exceeds 30 characters.
    case nicknameTooLong
}

// MARK: - Localization

extension CreateKudoFieldError {

    /// The `Localizable.xcstrings` key for this error's display message.
    ///
    /// Keys follow the pattern `kudos.create.error.<caseName>` and are
    /// defined in phase-08. Use with `NSLocalizedString` or `LocalizedStringKey`.
    var localizedKey: String {
        switch self {
        case .recipientRequired:      return "kudos.create.error.recipientRequired"
        case .cannotSendToSelf:       return "kudos.create.error.cannotSendToSelf"
        case .titleRequired:          return "kudos.create.error.titleRequired"
        case .titleTooLong:           return "kudos.create.error.titleTooLong"
        case .messageRequired:        return "kudos.create.error.messageRequired"
        case .messageWhitespaceOnly:  return "kudos.create.error.messageWhitespaceOnly"
        case .messageTooLong:         return "kudos.create.error.messageTooLong"
        case .hashtagsRequired:       return "kudos.create.error.hashtagsRequired"
        case .hashtagsTooMany:        return "kudos.create.error.hashtagsTooMany"
        case .imagesTooMany:          return "kudos.create.error.imagesTooMany"
        case .imageTooLarge:          return "kudos.create.error.imageTooLarge"
        case .unsupportedImageType:   return "kudos.create.error.unsupportedImageType"
        case .nicknameRequired:       return "kudos.create.error.nicknameRequired"
        case .nicknameTooLong:        return "kudos.create.error.nicknameTooLong"
        }
    }
}
