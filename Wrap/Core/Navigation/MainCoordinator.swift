import UIKit
import Hero

class MainCoordinator: Coordinator {
    var navigationController: UINavigationController
    var window: UIWindow?
    var childCoordinators = [Coordinator]()
    
    init(navigationController: UINavigationController, window: UIWindow?) {
        self.navigationController = navigationController
        self.navigationController.hero.isEnabled = true
        self.window = window
    }
    
    func start() {
        if NetworkManager.shared.hasValidToken() {
            showMainTab()
        } else {
            showLogin()
        }
    }
    
    func showLogin() {
        let child = AuthCoordinator(navigationController: navigationController)
        child.parentCoordinator = self
        childCoordinators.append(child)
        child.start()
        
        UIView.transition(with: window!, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.window?.rootViewController = self.navigationController
        })
    }
    
    func showForgotPassword() {
        let vc = ForgotPasswordViewController()
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: true)
    }
    
    func showMainTab() {
        guard NetworkManager.shared.hasValidToken() else {
            showLogin()
            return
        }
        
        let role = AuthManager.shared.userRole
        let tabBar = MainTabBarController(mainCoordinator: self, role: role)
        
        UIView.transition(with: window!, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.window?.rootViewController = tabBar
        })
    }
    
    // MARK: - Navigation helpers (used by VCs inside the tabs)
    private var currentNavigationController: UINavigationController? {
        if let tabBar = window?.rootViewController as? UITabBarController {
            return tabBar.selectedViewController as? UINavigationController
        }
        return navigationController
    }
    
    func showCatalog() {
        if NetworkManager.shared.hasValidToken() {
            showMainTab()
        } else {
            showLogin()
        }
    }
    
    func showCatalogCategory(category: CatalogCategory) {
        let vc = CatalogViewController(category: category)
        vc.coordinator = self
        if let nav = currentNavigationController {
            nav.hero.isEnabled = true
            nav.pushViewController(vc, animated: true)
        }
    }
    
    func showProductDetail(productId: UUID) {
        let vc = ProductDetailViewController(productId: productId)
        vc.coordinator = self
        if let nav = currentNavigationController {
            nav.hero.isEnabled = true
            nav.pushViewController(vc, animated: true)
        }
    }
    
    func showSearch() {
        let vc = SearchViewController()
        vc.coordinator = self
        if let nav = currentNavigationController {
            nav.hero.isEnabled = true
            nav.pushViewController(vc, animated: true)
        }
    }
    
    func showCart() {
        let vc = ReviewOrderViewController()
        vc.coordinator = self
        currentNavigationController?.pushViewController(vc, animated: true)
    }

    
    func showCheckoutPreview() {
        let vc = ReviewOrderViewController()
        vc.coordinator = self
        currentNavigationController?.pushViewController(vc, animated: true)
    }
    
    func showReviewOrder() {
        showCheckoutPreview()
    }
    
    func showOrderSuccess(orderId: String, paymentUrl: String) {
        let vc = OrderSuccessViewController(orderId: orderId, paymentUrl: paymentUrl)
        vc.coordinator = self
        currentNavigationController?.pushViewController(vc, animated: true)
    }
    
    func showOrderTracking(orderId: String) {
        let vc = OrderTrackingViewController(orderId: orderId)
        vc.coordinator = self
        
        // Dismiss any presented webview (SafariVC) before showing tracking
        window?.rootViewController?.dismiss(animated: true) {
            self.currentNavigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func showOrderHistory() {
        // Handled by the Orders tab, but keep for programmatic access
        if let tabBar = window?.rootViewController as? UITabBarController {
            tabBar.selectedIndex = 2 // Fixed index for Orders tab
        }
    }
    
    func showOrderDetail(orderId: UUID) {
        let vc = OrderDetailViewController(orderId: orderId)
        vc.coordinator = self
        currentNavigationController?.pushViewController(vc, animated: true)
    }
}
