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
        let body: [String: String] = [
            "email": email,
            "password": password
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            throw NetworkError.decodingError
        }

        // request is nonisolated (background), but returns a Sendable AuthResponse
        let response: AuthResponse = try await NetworkManager.shared.request(endpoint: "/auth/login", method: "POST", body: jsonData)

        // Await needed because NetworkManager is @MainActor
        NetworkManager.shared.setAuthToken(response.token)
        self.isBiometricsEnabled = response.biometricsEnabled

        if let fcmToken = Messaging.messaging().fcmToken {
            try? await syncFCMToken(fcmToken)
        }

        return response
    }

    func googleLogin(idToken: String) async throws {
        NetworkManager.shared.setAuthToken(idToken)

        var body: [String: String] = [:]
        if let fcmToken = Messaging.messaging().fcmToken {
            body["fcm_token"] = fcmToken
        }

        let jsonData = try? JSONSerialization.data(withJSONObject: body)
        let user: UserData = try await NetworkManager.shared.request(endpoint: "/user/sync", method: "POST", body: jsonData)
        self.isBiometricsEnabled = user.biometricsEnabled
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

        let body = ["fcm_token": fcmToken]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return }

        let _: UserSyncResponse = try await NetworkManager.shared.request(endpoint: "/user/sync", method: "POST", body: jsonData)
    }
}
