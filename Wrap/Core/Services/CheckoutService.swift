import Foundation

@MainActor
class CheckoutService {
    static let shared = CheckoutService()
    private init() {}
    
    func previewCheckout(items: [CartItem], address: [String: String]?) async throws -> CheckoutPreviewResponse {
        let payload: [String: Any] = [
            "items": items.map { [
                "variant_id": $0.variantId.uuidString.lowercased(),
                "quantity": $0.quantity
            ]},
            "address": address ?? [:]
        ]
        let body = try JSONSerialization.data(withJSONObject: payload)
        return try await NetworkManager.shared.request(endpoint: "/checkout/preview", method: "POST", body: body)
    }
    
    func placeOrder(items: [CartItem], address: [String: String], idempotencyKey: String, linkedAccountId: UUID? = nil) async throws -> OrderResponse {
        var payload: [String: Any] = [
            "items": items.map { [
                "variant_id": $0.variantId.uuidString.lowercased(),
                "quantity": $0.quantity
            ]},
            "address": address,
            "idempotency_key": idempotencyKey
        ]
        if let laID = linkedAccountId {
            payload["linked_account_id"] = laID.uuidString.lowercased()
        }
        let body = try JSONSerialization.data(withJSONObject: payload)
        return try await NetworkManager.shared.request(endpoint: "/checkout/place", method: "POST", body: body)
    }
    
    func syncCart(items: [CartItem]) async throws {
        let payload: [String: Any] = [
            "items": items.map { [
                "variant_id": $0.variantId.uuidString.lowercased(),
                "quantity": $0.quantity
            ]}
        ]
        let body = try JSONSerialization.data(withJSONObject: payload)
        let _: [String: String] = try await NetworkManager.shared.request(endpoint: "/user/cart/sync", method: "POST", body: body)
    }
}
