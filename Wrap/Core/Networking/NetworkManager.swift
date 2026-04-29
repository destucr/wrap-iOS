import Foundation

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case unauthorized // 401
    case notFound     // 404
    case conflict     // 409
}

@MainActor
class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = Environment.baseURL.absoluteString
    private var authToken: String? {
        didSet {
            if let data = authToken?.data(using: .utf8) {
                KeychainHelper.shared.save(data, service: "com.wrap.auth", account: "token")
            } else {
                KeychainHelper.shared.delete(service: "com.wrap.auth", account: "token")
            }
        }
    }

    private init() {
        if let data = KeychainHelper.shared.read(service: "com.wrap.auth", account: "token") {
            self.authToken = String(data: data, encoding: .utf8)
        }
    }

    func setAuthToken(_ token: String) { self.authToken = token.isEmpty ? nil : token }
    func hasValidToken() -> Bool { authToken != nil }

    @discardableResult
    nonisolated func request<T: Codable & Sendable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> T {
        // Fetch state from MainActor before jumping to background
        let token = await MainActor.run { self.authToken }

        guard let url = URL(string: "\(baseURL)\(endpoint)") else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError("Request Failed")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
        }
        return try decoder.decode(T.self, from: data)
    }
}

