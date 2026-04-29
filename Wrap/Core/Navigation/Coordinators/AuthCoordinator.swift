import UIKit

final class AuthCoordinator: Coordinator {
    var navigationController: UINavigationController
    weak var parentCoordinator: MainCoordinator?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let vc = LoginViewController()
        vc.coordinator = parentCoordinator // For now, still pointing to main for legacy support
        navigationController.viewControllers = [vc]
    }
}
