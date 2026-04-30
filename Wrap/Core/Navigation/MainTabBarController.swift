import UIKit

class MainTabBarController: UITabBarController {
    
    private var homeCoordinator: HomeCoordinator?
    private var checkoutCoordinator: CheckoutCoordinator?
    private var ordersCoordinator: OrdersCoordinator?
    private var profileCoordinator: ProfileCoordinator?
    private var role: UserRole
    
    init(mainCoordinator: MainCoordinator, role: UserRole) {
        self.role = role
        
        // Always need Profile
        self.profileCoordinator = ProfileCoordinator(navigationController: WrapNavigationController())
        profileCoordinator?.parentCoordinator = mainCoordinator
        
        if role == .driver {
            // Driver only needs Logistics and Profile
            // (LogisticsCoordinator will be implemented next)
            self.ordersCoordinator = OrdersCoordinator(navigationController: WrapNavigationController())
            ordersCoordinator?.parentCoordinator = mainCoordinator
        } else {
            // Customer needs the full shopping experience
            self.homeCoordinator = HomeCoordinator(navigationController: WrapNavigationController())
            self.checkoutCoordinator = CheckoutCoordinator(navigationController: WrapNavigationController())
            self.ordersCoordinator = OrdersCoordinator(navigationController: WrapNavigationController())
            
            homeCoordinator?.parentCoordinator = mainCoordinator
            checkoutCoordinator?.parentCoordinator = mainCoordinator
            ordersCoordinator?.parentCoordinator = mainCoordinator
        }
        
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
        
        if role == .customer {
            NotificationCenter.default.addObserver(self, selector: #selector(cartDidUpdate), name: .cartUpdated, object: nil)
            updateCartBadge()
        }
    }
    
    @objc private func cartDidUpdate() {
        updateCartBadge()
    }
    
    private func updateCartBadge() {
        if role == .customer, let cartTab = tabBar.items?[safe: 1] {
            let count = CartManager.shared.totalCount
            cartTab.badgeValue = count > 0 ? "\(count)" : nil
            cartTab.badgeColor = Brand.primary
        }
    }
    
    private func setupTabs() {
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        var viewControllers: [UIViewController] = []
        
        if role == .driver {
            // 1. Driver Queue (Using Orders for now as placeholder)
            if let orders = ordersCoordinator {
                orders.start()
                orders.navigationController.tabBarItem = UITabBarItem(
                    title: "Queue",
                    image: UIImage(systemName: "shippingbox", withConfiguration: config),
                    selectedImage: UIImage(systemName: "shippingbox.fill", withConfiguration: config)
                )
                viewControllers.append(orders.navigationController)
            }
        } else {
            // 1. Catalog Tab
            if let home = homeCoordinator {
                home.start()
                home.navigationController.tabBarItem = UITabBarItem(
                    title: "Shop",
                    image: UIImage(systemName: "bag", withConfiguration: config),
                    selectedImage: UIImage(systemName: "bag.fill", withConfiguration: config)
                )
                viewControllers.append(home.navigationController)
            }
            
            // 2. Cart Tab
            if let checkout = checkoutCoordinator {
                checkout.start()
                checkout.navigationController.tabBarItem = UITabBarItem(
                    title: "Cart",
                    image: UIImage(systemName: "cart", withConfiguration: config),
                    selectedImage: UIImage(systemName: "cart.fill", withConfiguration: config)
                )
                viewControllers.append(checkout.navigationController)
            }
            
            // 3. Orders Tab
            if let orders = ordersCoordinator {
                orders.start()
                orders.navigationController.tabBarItem = UITabBarItem(
                    title: "Orders",
                    image: UIImage(systemName: "clock", withConfiguration: config),
                    selectedImage: UIImage(systemName: "clock.fill", withConfiguration: config)
                )
                viewControllers.append(orders.navigationController)
            }
        }
        
        // 4. Profile Tab (Common)
        if let profile = profileCoordinator {
            profile.start()
            profile.navigationController.tabBarItem = UITabBarItem(
                title: "Profile",
                image: UIImage(systemName: "person.circle", withConfiguration: config),
                selectedImage: UIImage(systemName: "person.circle.fill", withConfiguration: config)
            )
            viewControllers.append(profile.navigationController)
        }
        
        self.viewControllers = viewControllers
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
