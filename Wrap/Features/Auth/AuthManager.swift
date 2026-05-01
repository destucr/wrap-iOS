import Foundation
import FirebaseMessaging
import FirebaseAuth

@MainActor // Ensures thread-safe access to UserDefaults and NetworkManager calls
class AuthManager {
    static let shared = AuthManager()

    private let biometricsPrefKey = "com.wrap.biometricsEnabled"
    private let userRoleKey = "com.wrap.userRole"

    var userRole: UserRole {
        get {
            let rawValue = UserDefaults.standard.string(forKey: userRoleKey) ?? UserRole.customer.rawValue
            return UserRole(rawValue: rawValue) ?? .customer
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: userRoleKey)
        }
    }

    var isBiometricsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: biometricsPrefKey) }
        set { UserDefaults.standard.set(newValue, forKey: biometricsPrefKey) }
    }

    private init() {}

    func login(email: String, password: String) async throws -> AuthResponse {
        print("🔐 [Auth] Starting login for \(email)...")
        let response = try await AuthService.shared.login(email: email, password: password)
        print("✅ [Auth] Login successful. User ID: \(response.id)")

        // Await needed because NetworkManager is @MainActor
        NetworkManager.shared.setAuthToken(response.token)
        setRefreshToken(response.refreshToken)
        self.isBiometricsEnabled = response.biometricsEnabled
        self.userRole = response.role

        if let fcmToken = Messaging.messaging().fcmToken {
            print("📲 [Auth] Syncing FCM Token...")
            try? await syncFCMToken(fcmToken)
        }

        // Populate user's saved cart after successful login
        print("🛒 [Auth] Fetching saved cart...")
        try? await CartManager.shared.fetchCart()

        return response
    }

    func setRefreshToken(_ token: String) {
        if let data = token.data(using: .utf8) {
            KeychainHelper.shared.save(data, service: "com.wrap.auth", account: "refresh_token")
        } else {
            KeychainHelper.shared.delete(service: "com.wrap.auth", account: "refresh_token")
        }
    }

    func getRefreshToken() -> String? {
        if let data = KeychainHelper.shared.read(service: "com.wrap.auth", account: "refresh_token") {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    func googleLogin(idToken: String, accessToken: String) async throws {
        // 1. Exchange Google Credentials for Firebase Credentials
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        // 2. Sign in to Firebase on the device
        let authResult = try await Auth.auth().signIn(with: credential)
        
        // 3. Get the actual Firebase ID Token (this is what the backend expects)
        let firebaseIDToken = try await authResult.user.getIDToken()
        
        // 4. Update local session
        NetworkManager.shared.setAuthToken(firebaseIDToken)
        
        // Firebase Auth result user has a refreshToken we should save
        if let refreshToken = authResult.user.refreshToken {
            setRefreshToken(refreshToken)
        }

        // 5. Sync with backend (This creates/updates the user in Postgres)
        let fcmToken = Messaging.messaging().fcmToken ?? ""
        let user = try await UserService.shared.syncUser(fcmToken: fcmToken)
        
        // Sync local biometric preference with backend
        self.isBiometricsEnabled = user.biometricsEnabled
        self.userRole = user.role

        // Populate user's saved cart after successful login
        try? await CartManager.shared.fetchCart()
    }

    func saveCredentials(email: String, password: String) {
        let credentials = ["email": email, "password": password]
        if let data = try? JSONEncoder().encode(credentials) {
            KeychainHelper.shared.save(data, service: "com.wrap.auth", account: "credentials")
        }
    }

    func getCredentials() -> (email: String, password: String)? {
        guard let data = KeychainHelper.shared.read(service: "com.wrap.auth", account: "credentials"),
              let credentials = try? JSONDecoder().decode([String: String].self, from: data),
              let email = credentials["email"],
              let password = credentials["password"] else {
            return nil
        }
        return (email, password)
    }

    func syncFCMToken(_ fcmToken: String) async throws {
        // Await check for @MainActor NetworkManager property
        guard NetworkManager.shared.hasValidToken() else { return }
        try await UserService.shared.syncUser(fcmToken: fcmToken)
    }

    func logout() {
        NetworkManager.shared.setAuthToken("")
        setRefreshToken("")
        UserDefaults.standard.removeObject(forKey: userRoleKey)
    }
    
    /// Proactively checks if the current session is still valid on this device
    func validateSession() async -> Bool {
        guard hasValidToken() else { return false }
        
        do {
            // Lightweight call to check status
            let _: [String: String] = try await NetworkManager.shared.request(endpoint: "/auth/status")
            return true
        } catch let error as NetworkError {
            if case .deviceMismatch = error {
                print("Proactive Check: Device Mismatch detected")
                return false
            }
            if case .unauthorized = error {
                return false
            }
            // For other network errors (offline), assume true to let cached UI show
            return true
        } catch {
            return true
        }
    }
}
