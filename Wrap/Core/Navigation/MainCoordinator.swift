import UIKit

class MainCoordinator: Coordinator {
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        showLogin()
    }
    
    func showLogin() {
        let vc = LoginViewController()
        vc.coordinator = self // We'll add this property to LoginViewController
        navigationController.viewControllers = [vc]
    }
    
    func showCatalog() {
        let vc = CatalogViewController()
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: true)
    }
    
    func showProductDetail(productId: UUID) {
        let vc = ProductDetailViewController(productId: productId)
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: true)
    }
    
    func showCart() {
        let vc = CartViewController()
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: true)
    }
    
    func showCheckoutPreview() {
        let vc = CheckoutPreviewViewController()
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: true)
    }
    
    func showOrderSuccess(orderId: String, paymentUrl: String) {
        let vc = OrderSuccessViewController(orderId: orderId, paymentUrl: paymentUrl)
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: true)
    }
}
