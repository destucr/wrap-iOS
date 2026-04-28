import Foundation
import FirebaseMessaging

struct AuthResponse: Codable {
    let token: String
    let isEmailVerified: Bool
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case token
        case isEmailVerified = "is_email_verified"
        case userId = "user_id"
    }
}

struct UserSyncResponse: Codable {
    let message: String?
}

class AuthManager {
    static let shared = AuthManager()
    
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
        let _: UserSyncResponse = try await NetworkManager.shared.request(endpoint: "/user/sync", method: "POST", body: jsonData)
    }
    
    func syncFCMToken(_ fcmToken: String) async throws {
        // Only sync if we have a valid auth token
        guard NetworkManager.shared.hasValidToken() else { return }
        
        let body = ["fcm_token": fcmToken]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return }
        
        let _: UserSyncResponse = try await NetworkManager.shared.request(endpoint: "/user/sync", method: "POST", body: jsonData)
    }
}
