import Foundation
import SwiftData
import UIKit

struct OrderResponse: Codable {
    let orderId: UUID
    let total: Double
    let expiresAt: Date
    let paymentUrl: String
    
    enum CodingKeys: String, CodingKey {
        case total
        case orderId = "order_id"
        case expiresAt = "expires_at"
        case paymentUrl = "payment_url"
    }
}

class CartManager {
    static let shared = CartManager()
    
    private var context: ModelContext?
    private var isSyncing = false
    
    private init() {}
    
    func setup(context: ModelContext) {
        self.context = context
    }
    
    // MARK: - Local Logic (SwiftData)
    var items: [CartItem] {
        let descriptor = FetchDescriptor<CartItem>(sortBy: [SortDescriptor(\.addedDate)])
        return (try? context?.fetch(descriptor)) ?? []
    }
    
    func add(variantId: UUID, name: String, price: Double, quantity: Int = 1) {
        let descriptor = FetchDescriptor<CartItem>(predicate: #Predicate { $0.variantId == variantId })
        
        if let existingItem = try? context?.fetch(descriptor).first {
            existingItem.quantity += quantity
        } else {
            let newItem = CartItem(variantId: variantId, name: name, price: price, quantity: quantity)
            context?.insert(newItem)
        }
        
        try? context?.save()
        NotificationCenter.default.post(name: .cartUpdated, object: nil)
    }

    func setQuantity(variantId: UUID, quantity: Int) {
        let descriptor = FetchDescriptor<CartItem>(predicate: #Predicate { $0.variantId == variantId })
        if let existingItem = try? context?.fetch(descriptor).first {
            if quantity <= 0 {
                context?.delete(existingItem)
            } else {
                existingItem.quantity = quantity
            }
            try? context?.save()
            NotificationCenter.default.post(name: .cartUpdated, object: nil)
        }
    }
    
    func remove(variantId: UUID) {
        let descriptor = FetchDescriptor<CartItem>(predicate: #Predicate { $0.variantId == variantId })
        if let existingItem = try? context?.fetch(descriptor).first {
            context?.delete(existingItem)
            try? context?.save()
            NotificationCenter.default.post(name: .cartUpdated, object: nil)
        }
    }
    
    func clear() {
        try? context?.delete(model: CartItem.self)
        try? context?.save()
        NotificationCenter.default.post(name: .cartUpdated, object: nil)
    }
    
    var totalAmount: Double {
        return items.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }
    
    var totalCount: Int {
        return items.reduce(0) { $0 + $1.quantity }
    }

    func quantity(for variantId: UUID) -> Int {
        let descriptor = FetchDescriptor<CartItem>(predicate: #Predicate { $0.variantId == variantId })
        return (try? context?.fetch(descriptor).first)?.quantity ?? 0
    }
    
    // MARK: - Sync Logic
    func syncWithBackend() async throws {
        guard !isSyncing else { return }
        isSyncing = true
        
        defer { isSyncing = false }
        
        let payload: [String: Any] = [
            "items": items.map { [
                "variant_id": $0.variantId.uuidString.lowercased(),
                "quantity": $0.quantity
            ]}
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            throw NetworkError.decodingError
        }
        
        let _: [String: String] = try await NetworkManager.shared.request(endpoint: "/user/cart/sync", method: "POST", body: jsonData)
    }
    
    func placeOrder(address: [String: String]) async throws -> OrderResponse {
        let payload: [String: Any] = [
            "items": items.map { [
                "variant_id": $0.variantId.uuidString.lowercased(),
                "quantity": $0.quantity
            ]},
            "address": address
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            throw NetworkError.decodingError
        }
        
        return try await NetworkManager.shared.request(endpoint: "/checkout/place", method: "POST", body: jsonData)
    }
}

extension NSNotification.Name {
    static let cartUpdated = NSNotification.Name("cartUpdated")
}
