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

class NetworkManager {
    static let shared = NetworkManager()
    
    private let baseURL = Environment.baseURL.absoluteString
    private var authToken: String? {
        didSet {
            if let token = authToken {
                if let data = token.data(using: .utf8) {
                    KeychainHelper.shared.save(data, service: "com.wrap.auth", account: "token")
                }
            } else {
                KeychainHelper.shared.delete(service: "com.wrap.auth", account: "token")
            }
        }
    }
    
    private init() {
        if let data = KeychainHelper.shared.read(service: "com.wrap.auth", account: "token"),
           let token = String(data: data, encoding: .utf8) {
            self.authToken = token
        }
    }
    
    func setAuthToken(_ token: String) {
        if token.isEmpty {
            self.authToken = nil
        } else {
            self.authToken = token
        }
    }
    
    func hasValidToken() -> Bool {
        return authToken != nil
    }
    
    @discardableResult
    func request<T: Codable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        isLoadTest: Bool = false
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if isLoadTest {
            request.setValue("true", forHTTPHeaderField: "X-Load-Test")
            request.setValue(Environment.loadTestSecret, forHTTPHeaderField: "X-Load-Test-Secret")
        }
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw NetworkError.unauthorized
        case 404:
            throw NetworkError.notFound
        case 409:
            throw NetworkError.conflict
        default:
            throw NetworkError.serverError("Status Code: \(httpResponse.statusCode)")
        }
        
        do {
            let decoder = JSONDecoder()
            let isoFormatter = ISO8601DateFormatter()
            
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)

                // Create the formatter INSIDE the closure
                let formatter = ISO8601DateFormatter()

                // Try with fractional seconds
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = formatter.date(from: dateString) {
                    return date
                }

                // Fallback to standard
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: dateString) {
                    return date
                }

                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(dateString)")
            }

            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
}
