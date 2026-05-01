import UIKit
import SwiftData

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var coordinator: MainCoordinator?
    var container: ModelContainer?

    private enum StartupCheckResult: Sendable {
        case finished(Bool)
        case timeout
    }

    private func performStartupCheck() {
        Task {
            let result = await withTaskGroup(of: StartupCheckResult.self) { group -> StartupCheckResult in
                group.addTask {
                    let isValid = await AuthManager.shared.validateSession()
                    return StartupCheckResult.finished(isValid)
                }
                
                group.addTask {
                    try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
                    return StartupCheckResult.timeout
                }
                
                guard let first = await group.next() else {
                    group.cancelAll()
                    return StartupCheckResult.finished(false)
                }
                
                group.cancelAll()
                return first
            }
            
            switch result {
            case .finished(let isValid):
                if isValid {
                    coordinator?.start()
                } else {
                    if AuthManager.shared.hasValidToken {
                        AuthManager.shared.logout()
                        CartManager.shared.clear()
                        coordinator?.showLogin()
                        showSessionExpiredAlert()
                    } else {
                        coordinator?.showLogin()
                    }
                }
            case .timeout:
                showNetworkErrorAlert()
            }
        }
    }
    
    private func showSessionExpiredAlert() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            let alert = UIAlertController(
                title: "Sesi Berakhir",
                message: "Akun Anda telah masuk di perangkat lain. Silakan login kembali untuk melanjutkan.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.window?.rootViewController?.present(alert, animated: true)
        }
    }
    
    private func showNetworkErrorAlert() {
        let alert = UIAlertController(
            title: "Masalah Koneksi",
            message: "Gagal menghubungkan ke server. Silakan periksa koneksi internet Anda.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Coba Lagi", style: .default) { [weak self] _ in
            self?.performStartupCheck()
        })
        window?.rootViewController?.present(alert, animated: true)
    }
    
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
        
        performStartupCheck()
        
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
        if let urlContext = URLContexts.first {
            handleURL(urlContext.url)
        }
    }

    private func handleURL(_ url: URL) {
        if url.host == "payment", url.path == "/success" {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let orderId = components?.queryItems?.first(where: { $0.name == "order_id" })?.value ?? "LATEST"
            coordinator?.showOrderTracking(orderId: orderId)
        }
    }
}
