import Combine
import Foundation

final class LanguagePreference: ObservableObject {
    private static let userDefaultsKey = "app.language"

    @Published var current: AppLanguage {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: Self.userDefaultsKey)
        }
    }

    init() {
        if let stored = UserDefaults.standard.string(forKey: Self.userDefaultsKey),
           let language = AppLanguage(rawValue: stored) {
            current = language
        } else {
            current = .vi
        }
    }
}
