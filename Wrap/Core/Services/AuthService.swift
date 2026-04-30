import Foundation
import UIKit

@MainActor
class AuthService {
    static let shared = AuthService()
    private init() {}
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let payload = ["email": email, "password": password, "device_id": deviceID]
        let body = try JSONSerialization.data(withJSONObject: payload)
        return try await NetworkManager.shared.request(endpoint: "/auth/login", method: "POST", body: body)
    }
    
    func forgotPassword(email: String) async throws {
        let payload = ["email": email]
        let body = try JSONSerialization.data(withJSONObject: payload)
        let _: UserSyncResponse = try await NetworkManager.shared.request(endpoint: "/auth/forgot-password", method: "POST", body: body)
    }

    func refreshAccessToken(refreshToken: String) async throws -> (token: String, refreshToken: String) {
        let apiKey = Environment.firebaseWebAPIKey
        let url = URL(string: "https://securetoken.googleapis.com/v1/token?key=\(apiKey)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = "grant_type=refresh_token&refresh_token=\(refreshToken)"
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.unauthorized
        }
        
        struct FirebaseRefreshResponse: Codable {
            let access_token: String
            let refresh_token: String
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(FirebaseRefreshResponse.self, from: data)
        return (result.access_token, result.refresh_token)
    }
}
