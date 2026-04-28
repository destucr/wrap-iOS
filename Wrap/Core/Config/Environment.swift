import Foundation

enum Environment {
    
    private static let infoDictionary: [String: Any] = {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            fatalError("Config.plist not found. Please add it to the project.")
        }
        return dict
    }()
    
    // MARK: - Dynamic Keys
    static let baseURL: URL = {
        guard let string = infoDictionary["BASE_URL"] as? String, let url = URL(string: string) else {
            fatalError("BASE_URL not found in Config.plist")
        }
        return url
    }()
    
    static let firebaseProjectID = infoDictionary["FIREBASE_PROJECT_ID"] as? String ?? ""
    static let firebaseWebAPIKey = infoDictionary["FIREBASE_WEB_API_KEY"] as? String ?? ""
    static let onesignalAppID = infoDictionary["ONESIGNAL_APP_ID"] as? String ?? ""
    static let loadTestSecret = infoDictionary["LOAD_TEST_SECRET"] as? String ?? ""
    
    // MARK: - Mode
    static let isDevelopment: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
}
