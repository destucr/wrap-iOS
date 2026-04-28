import Foundation

struct AuthResponse: Codable {
    let token: String
    let registered: Bool
}

class AuthManager {
    static let shared = AuthManager()
    
    private init() {}
    
    func login(email: String, password: String, completion: @escaping (Result<AuthResponse, NetworkError>) -> Void) {
        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            completion(.failure(.decodingError))
            return
        }
        
        NetworkManager.shared.request(endpoint: "/auth/login", method: "POST", body: jsonData) { (result: Result<AuthResponse, NetworkError>) in
            switch result {
            case .success(let response):
                NetworkManager.shared.setAuthToken(response.token)
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
