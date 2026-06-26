import Foundation

// MARK: - ProfileSummary

/// Lightweight profile snapshot used by the Create Kudo form.
/// Production code maps from `profiles` table; previews use mock values.
struct ProfileSummary: Identifiable, Hashable, Sendable {
    let id: UUID
    let displayName: String
    let employeeCode: String?
    let avatarURL: URL?
    let department: String?
}

// MARK: - ProfileSummary mock data (sourced from Figma nodes I6891:17451 / I6891:17452)

extension ProfileSummary {
    /// Preview / design-time fixtures derived directly from Figma text nodes.
    static let mockResults: [ProfileSummary] = [
        ProfileSummary(id: UUID(), displayName: "Dương Huỳnh Xuân Nhật", employeeCode: nil, avatarURL: nil, department: "CECV1"),
        ProfileSummary(id: UUID(), displayName: "Dương Huỳnh Xuân Nhân", employeeCode: nil, avatarURL: nil, department: "CECV1")
    ]
}

// MARK: - ImageDraft

/// A locally-selected image pending upload.
struct ImageDraft: Identifiable, Hashable, Sendable {
    typealias ID = UUID
    let id: ID
    /// Local file URL returned by PhotosPicker.
    let localURL: URL
}

// MARK: - MarkdownMarker

/// Toolbar actions that insert Markdown markers into the message text.
enum MarkdownMarker: String, CaseIterable {
    case bold       = "**"
    case italic     = "_"
    case strikethrough = "~~"
    case orderedList = "1. "
    case link       = "[]()"
    case quote      = "> "
}

// MARK: - FieldError

/// A validation error bound to a named field.
///
/// `localizationKey` is the `Localizable.xcstrings` key for the error message;
/// the view layer can resolve it via `LocalizedStringKey(key)` when surfacing
/// the copy. Today the view only uses `field` to drive error styling, but the
/// key is carried so future inline-error UIs don't need a new pipe.
struct FieldError: Identifiable, Hashable {
    enum Field: String {
        case recipient, title, message, hashtag, image, nickname
    }
    let id: UUID
    let field: Field
    let localizationKey: String

    init(field: Field, localizationKey: String) {
        self.id = UUID()
        self.field = field
        self.localizationKey = localizationKey
    }
}
