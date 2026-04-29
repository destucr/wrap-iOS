import UIKit

class MainTabBarController: UITabBarController {
    
    weak var mainCoordinator: MainCoordinator?
    
    init(coordinator: MainCoordinator) {
        self.mainCoordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        tabBar.tintColor = Brand.primary
        tabBar.backgroundColor = .systemBackground
        
        NotificationCenter.default.addObserver(self, selector: #selector(cartDidUpdate), name: .cartUpdated, object: nil)
        updateCartBadge()
    }
    
    @objc private func cartDidUpdate() {
        updateCartBadge()
    }
    
    private func updateCartBadge() {
        if let cartTab = tabBar.items?[1] {
            let count = CartManager.shared.totalCount
            cartTab.badgeValue = count > 0 ? "\(count)" : nil
            cartTab.badgeColor = Brand.primary
        }
    }
    
    private func setupTabs() {
        // 1. Catalog Tab
        let catalogVC = HomeViewController()
        catalogVC.coordinator = mainCoordinator
        let catalogNav = UINavigationController(rootViewController: catalogVC)
        catalogNav.tabBarItem = UITabBarItem(title: "Shop", image: UIImage(systemName: "bag"), tag: 0)
        
        // 2. Cart Tab
        let cartVC = ReviewOrderViewController()
        cartVC.coordinator = mainCoordinator
        let cartNav = UINavigationController(rootViewController: cartVC)
        cartNav.tabBarItem = UITabBarItem(title: "Cart", image: UIImage(systemName: "cart"), tag: 1)
        
        // 3. Orders Tab
        let ordersVC = OrderHistoryViewController()
        ordersVC.coordinator = mainCoordinator
        let ordersNav = UINavigationController(rootViewController: ordersVC)
        ordersNav.tabBarItem = UITabBarItem(title: "Order History", image: UIImage(systemName: "clock.arrow.circlepath"), tag: 2)
        
        // 4. Profile Tab
        let profileVC = ProfileViewController()
        profileVC.coordinator = mainCoordinator
        let profileNav = UINavigationController(rootViewController: profileVC)
        profileNav.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person.circle"), tag: 3)
        
        viewControllers = [catalogNav, cartNav, ordersNav, profileNav]
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
