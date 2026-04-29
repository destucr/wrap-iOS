import Foundation

@MainActor
class AuthService {
    static let shared = AuthService()
    private init() {}
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let payload = ["email": email, "password": password]
        let body = try JSONSerialization.data(withJSONObject: payload)
        return try await NetworkManager.shared.request(endpoint: "/auth/login", method: "POST", body: body)
    }
}
