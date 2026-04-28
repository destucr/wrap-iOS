import Foundation
import FirebaseMessaging

struct AuthResponse: Codable {
    let token: String
    let isEmailVerified: Bool
    let userId: String
    let biometricsEnabled: Bool
    
    enum CodingKeys: String, CodingKey {
        case token
        case isEmailVerified = "is_email_verified"
        case userId = "user_id"
        case biometricsEnabled = "biometrics_enabled"
    }
}

struct UserSyncResponse: Codable {
    let message: String?
}

struct User: Codable {
    let id: UUID
    let email: String
    let fullName: String
    let biometricsEnabled: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case fullName = "full_name"
        case biometricsEnabled = "biometrics_enabled"
    }
}

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
        
        let response: AuthResponse = try await NetworkManager.shared.request(endpoint: "/auth/login", method: "POST", body: jsonData)
        NetworkManager.shared.setAuthToken(response.token)
        self.isBiometricsEnabled = response.biometricsEnabled
        
        // Sync FCM token if available after login
        if let fcmToken = Messaging.messaging().fcmToken {
            try? await syncFCMToken(fcmToken)
        }
        
        return response
    }
    
    func googleLogin(idToken: String) async throws {
        NetworkManager.shared.setAuthToken(idToken)
        
        // Sync User with Backend (Silent Registration)
        var body: [String: String] = [:]
        if let fcmToken = Messaging.messaging().fcmToken {
            body["fcm_token"] = fcmToken
        }
        
        let jsonData = try? JSONSerialization.data(withJSONObject: body)
        let user: User = try await NetworkManager.shared.request(endpoint: "/user/sync", method: "POST", body: jsonData)
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
        // Only sync if we have a valid auth token
        guard NetworkManager.shared.hasValidToken() else { return }
        
        let body = ["fcm_token": fcmToken]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return }
        
        let _: UserSyncResponse = try await NetworkManager.shared.request(endpoint: "/user/sync", method: "POST", body: jsonData)
    }
}
