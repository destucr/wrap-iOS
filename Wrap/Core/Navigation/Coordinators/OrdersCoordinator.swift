import UIKit

final class OrdersCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators = [Coordinator]()
    weak var parentCoordinator: MainCoordinator?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let vc = OrderHistoryViewController()
        vc.coordinator = parentCoordinator
        navigationController.viewControllers = [vc]
    }
}
