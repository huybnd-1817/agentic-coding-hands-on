import UIKit

extension UIApplication {
    /// Traverses the window hierarchy to find the topmost presented `UIViewController`.
    ///
    /// Used by `LoginViewContainer` to obtain a presenting controller for
    /// `GIDSignIn.signIn(withPresenting:)` without coupling the SwiftUI view
    /// tree to UIKit lifecycle directly.
    var topViewController: UIViewController? {
        guard let windowScene = connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let rootViewController = windowScene.windows
            .first(where: { $0.isKeyWindow })?.rootViewController
        else {
            return nil
        }
        return topMost(of: rootViewController)
    }

    private func topMost(of viewController: UIViewController) -> UIViewController {
        if let presented = viewController.presentedViewController {
            return topMost(of: presented)
        }
        if let navController = viewController as? UINavigationController,
           let visible = navController.visibleViewController {
            return topMost(of: visible)
        }
        if let tabController = viewController as? UITabBarController,
           let selected = tabController.selectedViewController {
            return topMost(of: selected)
        }
        return viewController
    }
}
