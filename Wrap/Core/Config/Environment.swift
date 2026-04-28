import Foundation

/// App-wide configuration and environment variables.
///
/// **SECURITY WARNING:** Never include secret keys (like API Secret Keys, 
/// Private Keys, or Database Passwords) here. Only public identifiers 
/// should be stored in the client-side binary.
enum Environment {
    
    // MARK: - Backend
    static let baseURL = URL(string: "http://104.43.92.71/api/v1")!
    
    // MARK: - Firebase
    /// Note: Most Firebase config is handled automatically by GoogleService-Info.plist
    static let firebaseProjectID = "wrap-c20c0"
    static let firebaseWebAPIKey = "AIzaSyBqi5i8Ki9bmPSsTuumVYLOlQNhM5_C9bs"
    
    // MARK: - OneSignal
    /// Only the App ID is safe for the client app. The API Key is for backend only.
    static let onesignalAppID = "27fb24e1-39fc-48e9-a5b3-14b0bf50e7cd"
    
    // MARK: - Mode
    static let isDevelopment: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
}
