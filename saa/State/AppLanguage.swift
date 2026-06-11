import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case vi
    case en
    case ja

    var id: String { rawValue }

    var label: String {
        switch self {
        case .vi: "VN"
        case .en: "EN"
        case .ja: "JA"
        }
    }

    var localeIdentifier: String { rawValue }
}
