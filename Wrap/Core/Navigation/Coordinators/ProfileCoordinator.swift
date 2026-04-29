import UIKit

final class ProfileCoordinator: Coordinator {
    var navigationController: UINavigationController
    weak var parentCoordinator: MainCoordinator?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let vc = ProfileViewController()
        vc.coordinator = parentCoordinator
        navigationController.viewControllers = [vc]
    }
}
