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
        tabBar.unselectedItemTintColor = Brand.Text.secondary
        
        // Configure Tab Bar Appearance for iOS 15+
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            
            // Icon sizing (24pt)
            let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
            appearance.stackedLayoutAppearance.normal.iconColor = Brand.Text.secondary
            appearance.stackedLayoutAppearance.selected.iconColor = Brand.primary
            
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        } else {
            tabBar.backgroundColor = .white
            tabBar.isTranslucent = false
        }
        
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
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        
        // 1. Catalog Tab
        let catalogVC = HomeViewController()
        catalogVC.coordinator = mainCoordinator
        let catalogNav = UINavigationController(rootViewController: catalogVC)
        catalogNav.tabBarItem = UITabBarItem(
            title: "Shop",
            image: UIImage(systemName: "bag", withConfiguration: config),
            selectedImage: UIImage(systemName: "bag.fill", withConfiguration: config)
        )
        
        // 2. Cart Tab
        let cartVC = ReviewOrderViewController()
        cartVC.coordinator = mainCoordinator
        let cartNav = UINavigationController(rootViewController: cartVC)
        cartNav.tabBarItem = UITabBarItem(
            title: "Cart",
            image: UIImage(systemName: "cart", withConfiguration: config),
            selectedImage: UIImage(systemName: "cart.fill", withConfiguration: config)
        )
        
        // 3. Orders Tab
        let ordersVC = OrderHistoryViewController()
        ordersVC.coordinator = mainCoordinator
        let ordersNav = UINavigationController(rootViewController: ordersVC)
        ordersNav.tabBarItem = UITabBarItem(
            title: "Orders",
            image: UIImage(systemName: "clock", withConfiguration: config),
            selectedImage: UIImage(systemName: "clock.fill", withConfiguration: config)
        )
        
        // 4. Profile Tab
        let profileVC = ProfileViewController()
        profileVC.coordinator = mainCoordinator
        let profileNav = UINavigationController(rootViewController: profileVC)
        profileNav.tabBarItem = UITabBarItem(
            title: "Profile",
            image: UIImage(systemName: "person.circle", withConfiguration: config),
            selectedImage: UIImage(systemName: "person.circle.fill", withConfiguration: config)
        )
        
        viewControllers = [catalogNav, cartNav, ordersNav, profileNav]
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
