import Foundation

enum UserRole: String, Codable, Sendable {
    case customer
    case driver
    case admin
}

// MARK: - Models
// Using 'nonisolated' allows background decoding in Swift 6
nonisolated struct AuthResponse: Codable, Sendable {
    let token: String
    let refreshToken: String
    let expiresIn: String
    let isEmailVerified: Bool
    let id: UUID
    let firebaseUid: String
    let biometricsEnabled: Bool
    let role: UserRole

    enum CodingKeys: String, CodingKey {
        case token, role
        case id = "user_id"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case isEmailVerified = "is_email_verified"
        case firebaseUid = "firebase_uid"
        case biometricsEnabled = "biometrics_enabled"
    }
}

nonisolated struct UserData: Codable, Sendable {
    let id: UUID
    let email: String
    let fullName: String
    let fullAddress: String?
    let biometricsEnabled: Bool
    let role: UserRole

    enum CodingKeys: String, CodingKey {
        case id, email, role
        case fullName = "full_name"
        case fullAddress = "full_address"
        case biometricsEnabled = "biometrics_enabled"
    }
}

nonisolated struct UserSyncResponse: Codable, Sendable {
    let message: String?
}
