import Foundation

struct LinkedAccount: Codable {
    let id: UUID
    let userId: UUID
    let channelCode: String
    let tokenId: String
    let accountDetails: String
    let status: String
    let createdAt: String
    let balance: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, status, balance
        case userId = "user_id"
        case channelCode = "channel_code"
        case tokenId = "token_id"
        case accountDetails = "account_details"
        case createdAt = "created_at"
    }
}

struct LinkedAccountResponse: Codable {
    let accounts: [LinkedAccount]
}

struct LinkAccountInitializeResponse: Codable {
    let redirectUrl: String
    
    enum CodingKeys: String, CodingKey {
        case redirectUrl = "redirect_url"
    }
}

@MainActor
class PaymentService {
    static let shared = PaymentService()
    private init() {}
    
    func fetchLinkedAccounts() async throws -> [LinkedAccount] {
        let response: LinkedAccountResponse = try await NetworkManager.shared.request(endpoint: "/user/payments/linked-accounts")
        return response.accounts
    }
    
    func initializeLinking(channelCode: String) async throws -> String {
        let body = ["channel_code": channelCode]
        let response: LinkAccountInitializeResponse = try await NetworkManager.shared.request(endpoint: "/user/payments/link-account/initialize", method: "POST", body: body)
        return response.redirectUrl
    }
    
    func unlinkAccount(id: UUID) async throws {
        let _: [String: String] = try await NetworkManager.shared.request(endpoint: "/user/payments/linked-accounts/\(id.uuidString.lowercased())", method: "DELETE")
    }
}
