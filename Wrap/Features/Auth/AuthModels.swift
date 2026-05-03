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

nonisolated struct UserData: Codable, Sendable, Hashable, Equatable {
    let id: UUID
    let email: String
    let fullName: String
    let fullAddress: String?
    let phoneNumber: String?
    let postalCode: String?
    let latitude: Double?
    let longitude: Double?
    let biometricsEnabled: Bool
    let role: UserRole
    let driverStatus: DriverState?

    enum CodingKeys: String, CodingKey {
        case id, email, role, latitude, longitude
        case fullName = "full_name"
        case fullAddress = "full_address"
        case phoneNumber = "phone_number"
        case postalCode = "postal_code"
        case biometricsEnabled = "biometrics_enabled"
        case driverStatus = "driver_status"
    }
}

nonisolated struct SavedAddress: Codable, Sendable, Hashable, Equatable {
    let id: UUID
    let userId: UUID?
    let label: String
    let fullAddress: String
    let latitude: Double
    let longitude: Double
    let postalCode: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, label
        case userId = "user_id"
        case fullAddress = "full_address"
        case latitude, longitude
        case postalCode = "postal_code"
        case createdAt = "created_at"
    }
}

nonisolated struct UserSyncResponse: Codable, Sendable {
    let message: String?
}
