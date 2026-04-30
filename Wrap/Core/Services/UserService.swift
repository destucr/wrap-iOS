import Foundation

@MainActor
class UserService {
    static let shared = UserService()
    private init() {}
    
    func fetchProfile() async throws -> UserData {
        return try await NetworkManager.shared.request(endpoint: "/user/profile")
    }
    
    func syncUser(fcmToken: String) async throws -> UserData {
        let payload = ["fcm_token": fcmToken]
        let body = try JSONSerialization.data(withJSONObject: payload)
        return try await NetworkManager.shared.request(endpoint: "/user/sync", method: "POST", body: body)
    }
    
    func fetchOrderHistory() async throws -> [Order] {
        return try await NetworkManager.shared.request(endpoint: "/user/orders")
    }
    
    func fetchOrderDetail(id: UUID) async throws -> OrderDetailResponse {
        return try await NetworkManager.shared.request(endpoint: "/user/orders/\(id.uuidString.lowercased())")
    }
    
    func rateOrder(id: UUID, rating: Int, comment: String) async throws {
        let payload: [String: Any] = ["rating": rating, "comment": comment]
        let body = try JSONSerialization.data(withJSONObject: payload)
        let _: [String: String] = try await NetworkManager.shared.request(endpoint: "/user/orders/\(id.uuidString.lowercased())/rate", method: "POST", body: body)
    }
    
    func updatePhoneNumber(phoneNumber: String) async throws {
        let payload = ["phone_number": phoneNumber]
        let body = try JSONSerialization.data(withJSONObject: payload)
        let _: [String: String] = try await NetworkManager.shared.request(endpoint: "/user/phone-number", method: "PUT", body: body)
    }
    
    func updateProfile(fullName: String, address: String, postalCode: String, lat: Double, lon: Double) async throws {
        let payload: [String: Any] = [
            "full_address": address,
            "postal_code": postalCode,
            "latitude": lat,
            "longitude": lon
        ]
        let body = try JSONSerialization.data(withJSONObject: payload)
        let _: [String: String] = try await NetworkManager.shared.request(endpoint: "/user/address", method: "PUT", body: body)
        // Note: You may also need a backend endpoint for updating the full name
    }

    func updateSettings(biometricsEnabled: Bool) async throws {
        let payload = ["biometrics_enabled": biometricsEnabled]
        let body = try JSONSerialization.data(withJSONObject: payload)
        let _: [String: String] = try await NetworkManager.shared.request(endpoint: "/user/settings", method: "PUT", body: body)
    }
    
    func logout() async throws {
        let _: [String: String] = try await NetworkManager.shared.request(endpoint: "/user/logout", method: "POST")
    }
}
