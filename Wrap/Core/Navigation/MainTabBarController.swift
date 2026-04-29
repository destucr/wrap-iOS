import UIKit

class MainTabBarController: UITabBarController {
    
    private var homeCoordinator: HomeCoordinator
    private var checkoutCoordinator: CheckoutCoordinator
    private var ordersCoordinator: OrdersCoordinator
    private var profileCoordinator: ProfileCoordinator
    
    init(mainCoordinator: MainCoordinator) {
        self.homeCoordinator = HomeCoordinator(navigationController: UINavigationController())
        self.checkoutCoordinator = CheckoutCoordinator(navigationController: UINavigationController())
        self.ordersCoordinator = OrdersCoordinator(navigationController: UINavigationController())
        self.profileCoordinator = ProfileCoordinator(navigationController: UINavigationController())
        
        homeCoordinator.parentCoordinator = mainCoordinator
        checkoutCoordinator.parentCoordinator = mainCoordinator
        ordersCoordinator.parentCoordinator = mainCoordinator
        profileCoordinator.parentCoordinator = mainCoordinator
        
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
        homeCoordinator.start()
        homeCoordinator.navigationController.tabBarItem = UITabBarItem(
            title: "Shop",
            image: UIImage(systemName: "bag", withConfiguration: config),
            selectedImage: UIImage(systemName: "bag.fill", withConfiguration: config)
        )
        
        // 2. Cart Tab
        checkoutCoordinator.start()
        checkoutCoordinator.navigationController.tabBarItem = UITabBarItem(
            title: "Cart",
            image: UIImage(systemName: "cart", withConfiguration: config),
            selectedImage: UIImage(systemName: "cart.fill", withConfiguration: config)
        )
        
        // 3. Orders Tab
        ordersCoordinator.start()
        ordersCoordinator.navigationController.tabBarItem = UITabBarItem(
            title: "Orders",
            image: UIImage(systemName: "clock", withConfiguration: config),
            selectedImage: UIImage(systemName: "clock.fill", withConfiguration: config)
        )
        
        // 4. Profile Tab
        profileCoordinator.start()
        profileCoordinator.navigationController.tabBarItem = UITabBarItem(
            title: "Profile",
            image: UIImage(systemName: "person.circle", withConfiguration: config),
            selectedImage: UIImage(systemName: "person.circle.fill", withConfiguration: config)
        )
        
        viewControllers = [
            homeCoordinator.navigationController,
            checkoutCoordinator.navigationController,
            ordersCoordinator.navigationController,
            profileCoordinator.navigationController
        ]
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
