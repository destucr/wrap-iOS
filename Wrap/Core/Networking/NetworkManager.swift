import Foundation
import UIKit
import RxSwift
import RxRelay

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case unauthorized // 401
    case forbidden    // 403
    case deviceMismatch // 403 with code DEVICE_MISMATCH
    case notFound     // 404
    case conflict     // 409
}

enum AuthStatus {
    case authenticated
    case unauthorized
}

@MainActor
class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = Environment.baseURL.absoluteString
    
    // RxSwift Infrastructure
    private let authStatusRelay = BehaviorRelay<AuthStatus>(value: .authenticated)
    var authStatus: Observable<AuthStatus> {
        return authStatusRelay.asObservable()
    }

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

    func setAuthToken(_ token: String) { 
        self.authToken = token.isEmpty ? nil : token 
        authStatusRelay.accept(token.isEmpty ? .unauthorized : .authenticated)
    }
    func hasValidToken() -> Bool { authToken != nil }

    @discardableResult
    nonisolated func request<T: Codable & Sendable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> T {
        do {
            return try await performRequest(endpoint: endpoint, method: method, body: body)
        } catch let error as NetworkError {
            if case .unauthorized = error {
                // Attempt refresh
                let success = await attemptRefresh()
                if success {
                    // Retry once
                    return try await performRequest(endpoint: endpoint, method: method, body: body)
                }
            }
            throw error
        }
    }

    private nonisolated func performRequest<T: Codable & Sendable>(
        endpoint: String,
        method: String,
        body: Data?
    ) async throws -> T {
        // Fetch state from MainActor before jumping to background
        let token = await MainActor.run { self.authToken }

        guard let url = URL(string: "\(baseURL)\(endpoint)") else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let deviceID = await MainActor.run { UIDevice.current.identifierForVendor?.uuidString ?? "unknown" }
        request.setValue(deviceID, forHTTPHeaderField: "X-Device-ID")

        if let token = token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError("No Response")
        }

        print("🌐 [Network] \(method) \(endpoint) -> Status: \(httpResponse.statusCode)")
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📄 [Network] Response Body: \(jsonString)")
        }

        if httpResponse.statusCode == 401 {
            throw NetworkError.unauthorized
        }

        if httpResponse.statusCode == 403 {
            // Check for DEVICE_MISMATCH
            if let body = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let code = body["code"] as? String, code == "DEVICE_MISMATCH" {
                await MainActor.run {
                    NotificationCenter.default.post(name: .unauthorizedAccess, object: nil)
                }
                throw NetworkError.deviceMismatch
            }
            throw NetworkError.forbidden
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError("Request Failed with status: \(httpResponse.statusCode)")
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

    private nonisolated func attemptRefresh() async -> Bool {
        guard let refreshToken = await AuthManager.shared.getRefreshToken() else {
            return false
        }

        do {
            let (newToken, newRefreshToken) = try await AuthService.shared.refreshAccessToken(refreshToken: refreshToken)
            await MainActor.run {
                self.setAuthToken(newToken)
                AuthManager.shared.setRefreshToken(newRefreshToken)
            }
            return true
        } catch {
            print("Token refresh failed: \(error)")
            // If refresh fails, we might want to force logout here
            await MainActor.run {
                self.setAuthToken("")
                AuthManager.shared.setRefreshToken("")
                self.authStatusRelay.accept(.unauthorized)
                // Notify UI to show login if needed
                NotificationCenter.default.post(name: .unauthorizedAccess, object: nil)
            }
            return false
        }
    }
}

extension NSNotification.Name {
    static let unauthorizedAccess = NSNotification.Name("unauthorizedAccess")
}

