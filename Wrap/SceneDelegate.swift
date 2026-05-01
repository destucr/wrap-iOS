import UIKit
import SwiftData

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var coordinator: MainCoordinator?
    var container: ModelContainer?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Setup SwiftData
        do {
            container = try ModelContainer(for: CartItem.self)
            if let context = container?.mainContext {
                CartManager.shared.setup(context: context)
            }
        } catch {
            print("Failed to setup SwiftData: \(error)")
        }
        
        let navController = WrapNavigationController()
        window = UIWindow(windowScene: windowScene)
        
        coordinator = MainCoordinator(navigationController: navController, window: window)
        
        window?.rootViewController = UIViewController() // Splash placeholder
        window?.makeKeyAndVisible()
        
        Task {
            let isValid = await AuthManager.shared.validateSession()
            
            if isValid {
                coordinator?.start()
            } else {
                // If not valid but we had a token, it means we were kicked out
                if AuthManager.shared.hasValidToken() {
                    AuthManager.shared.logout()
                    CartManager.shared.clear()
                    
                    coordinator?.showLogin()
                    
                    // ELITE: Inform the user why they are back at Login
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        let alert = UIAlertController(
                            title: "Sesi Berakhir",
                            message: "Akun Anda telah masuk di perangkat lain. Silakan login kembali untuk melanjutkan.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.window?.rootViewController?.present(alert, animated: true)
                    }
                } else {
                    coordinator?.showLogin()
                }
            }
        }
        
        // Handle Cold Start from URL
        if let urlContext = connectionOptions.urlContexts.first {
            handleURL(urlContext.url)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handleURL(url)
    }
    
    private func handleURL(_ url: URL) {
        // Expected: wrapapp://payment/success?order_id=uuid
        guard url.scheme == "wrapapp" else { return }
        
        if url.host == "payment", url.path == "/success" {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let orderId = components?.queryItems?.first(where: { $0.name == "order_id" })?.value ?? "LATEST"
            coordinator?.showOrderTracking(orderId: orderId)
        }
    }
}
