import UIKit

final class CheckoutCoordinator: Coordinator {
    var navigationController: UINavigationController
    weak var parentCoordinator: MainCoordinator?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let vc = ReviewOrderViewController()
        vc.coordinator = parentCoordinator
        navigationController.viewControllers = [vc]
    }
}
