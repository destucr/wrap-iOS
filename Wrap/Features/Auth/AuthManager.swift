import Foundation
import FirebaseMessaging

@MainActor // Ensures thread-safe access to UserDefaults and NetworkManager calls
class AuthManager {
    static let shared = AuthManager()

    private let biometricsPrefKey = "com.wrap.biometricsEnabled"

    var isBiometricsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: biometricsPrefKey) }
        set { UserDefaults.standard.set(newValue, forKey: biometricsPrefKey) }
    }

    private init() {}

    func login(email: String, password: String) async throws -> AuthResponse {
        let response = try await AuthService.shared.login(email: email, password: password)

        // Await needed because NetworkManager is @MainActor
        NetworkManager.shared.setAuthToken(response.token)
        setRefreshToken(response.refreshToken)
        self.isBiometricsEnabled = response.biometricsEnabled

        if let fcmToken = Messaging.messaging().fcmToken {
            try? await syncFCMToken(fcmToken)
        }

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

    func googleLogin(idToken: String) async throws {
        NetworkManager.shared.setAuthToken(idToken)

        if let fcmToken = Messaging.messaging().fcmToken {
            try await UserService.shared.syncUser(fcmToken: fcmToken)
            // Fetch profile to get biometrics status after sync
            let user = try await UserService.shared.fetchProfile()
            self.isBiometricsEnabled = user.biometricsEnabled
        }
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
}
