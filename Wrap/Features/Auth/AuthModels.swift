import Foundation

// MARK: - Models
// Using 'nonisolated' allows background decoding in Swift 6
nonisolated struct AuthResponse: Codable, Sendable {
    let token: String
    let refreshToken: String
    let expiresIn: String
    let isEmailVerified: Bool
    let userId: String
    let biometricsEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case token
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case isEmailVerified = "is_email_verified"
        case userId = "user_id"
        case biometricsEnabled = "biometrics_enabled"
    }
}

nonisolated struct UserData: Codable, Sendable {
    let id: UUID
    let email: String
    let fullName: String
    let fullAddress: String?
    let biometricsEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case id, email
        case fullName = "full_name"
        case fullAddress = "full_address"
        case biometricsEnabled = "biometrics_enabled"
    }
}

nonisolated struct UserSyncResponse: Codable, Sendable {
    let message: String?
}
