import Foundation

@MainActor
final class LogisticsService {
    static let shared = LogisticsService()
    private init() {}
    
    func updateStatus(status: DriverState) async throws {
        let body = ["status": status.rawValue]
        let data = try JSONEncoder().encode(body)
        let _: [String: String] = try await NetworkManager.shared.request(endpoint: "/driver/logistics/status", method: "PATCH", body: data)
    }
    
    func updateLocation(lat: Double, lng: Double) async throws {
        let body = ["lat": lat, "lng": lng]
        let data = try JSONEncoder().encode(body)
        let _: [String: String] = try await NetworkManager.shared.request(endpoint: "/driver/location", method: "POST", body: data)
    }
}
