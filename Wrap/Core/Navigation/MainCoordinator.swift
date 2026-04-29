import UIKit

class MainCoordinator: Coordinator {
    var navigationController: UINavigationController
    var window: UIWindow?
    
    init(navigationController: UINavigationController, window: UIWindow?) {
        self.navigationController = navigationController
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
        let vc = LoginViewController()
        vc.coordinator = self
        navigationController.viewControllers = [vc]
        
        UIView.transition(with: window!, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.window?.rootViewController = self.navigationController
        })
    }
    
    func showMainTab() {
        guard NetworkManager.shared.hasValidToken() else {
            showLogin()
            return
        }
        
        let tabBar = MainTabBarController(coordinator: self)
        
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
        currentNavigationController?.pushViewController(vc, animated: true)
    }
    
    func showProductDetail(productId: UUID) {
        let vc = ProductDetailViewController(productId: productId)
        vc.coordinator = self
        currentNavigationController?.pushViewController(vc, animated: true)
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
