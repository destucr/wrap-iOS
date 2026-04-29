import Foundation
import SwiftData
import UIKit

// 1. Explicitly nonisolated and Sendable for background network decoding
nonisolated struct OrderResponse: Codable, Sendable {
    let orderId: UUID
    let total: Double
    let expiresAt: Date
    let paymentUrl: String

    nonisolated enum CodingKeys: String, CodingKey {
        case total
        case orderId = "order_id"
        case expiresAt = "expires_at"
        case paymentUrl = "payment_url"
    }
}

@MainActor
class CartManager: Sendable {
    static let shared = CartManager()
    
    private var context: ModelContext?
    private var isSyncing = false
    private var _idempotencyKey: String?
    
    private init() {}
    
    func setup(context: ModelContext) {
        self.context = context
    }

    var idempotencyKey: String {
        if let key = _idempotencyKey { return key }
        let newKey = UUID().uuidString.lowercased()
        _idempotencyKey = newKey
        return newKey
    }
    
    // MARK: - Local Logic (SwiftData)
    var items: [CartItem] {
        guard let context = context else { return [] }
        context.processPendingChanges()
        let descriptor = FetchDescriptor<CartItem>(sortBy: [SortDescriptor(\.addedDate)])
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func add(variantId: UUID, name: String, price: Double, quantity: Int = 1) {
        guard let context = context else { return }
        context.processPendingChanges()
        
        let descriptor = FetchDescriptor<CartItem>(predicate: #Predicate { $0.variantId == variantId })
        
        if let existingItem = try? context.fetch(descriptor).first {
            existingItem.quantity += quantity
        } else {
            let newItem = CartItem(variantId: variantId, name: name, price: price, quantity: quantity)
            context.insert(newItem)
        }
        
        saveAndNotify()
    }

    func setQuantity(variantId: UUID, quantity: Int, name: String? = nil, price: Double? = nil) {
        guard let context = context else { return }
        context.processPendingChanges()
        
        let descriptor = FetchDescriptor<CartItem>(predicate: #Predicate { $0.variantId == variantId })
        
        if let existingItem = try? context.fetch(descriptor).first {
            if quantity <= 0 {
                context.delete(existingItem)
            } else {
                existingItem.quantity = quantity
            }
        } else if quantity > 0, let name = name, let price = price {
            let newItem = CartItem(variantId: variantId, name: name, price: price, quantity: quantity)
            context.insert(newItem)
        }
        
        saveAndNotify()
    }
    
    private func saveAndNotify() {
        guard let context = context else { return }
        do {
            try context.save()
            // Force process changes to ensure other queries see it immediately
            context.processPendingChanges()
            _idempotencyKey = nil
            NotificationCenter.default.post(name: .cartUpdated, object: nil)
        } catch {
            print("Failed to save cart: \(error)")
        }
    }
    
    func remove(variantId: UUID) {
        guard let context = context else { return }
        context.processPendingChanges()
        let descriptor = FetchDescriptor<CartItem>(predicate: #Predicate { $0.variantId == variantId })
        if let existingItem = try? context.fetch(descriptor).first {
            context.delete(existingItem)
            saveAndNotify()
        }
    }
    
    func clear() {
        guard let context = context else { return }
        try? context.delete(model: CartItem.self)
        _idempotencyKey = nil
        saveAndNotify()
    }
    
    var totalAmount: Double {
        return items.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }
    
    var totalCount: Int {
        return items.reduce(0) { $0 + $1.quantity }
    }

    func quantity(for variantId: UUID) -> Int {
        guard let context = context else { return 0 }
        context.processPendingChanges()
        let descriptor = FetchDescriptor<CartItem>(predicate: #Predicate { $0.variantId == variantId })
        return (try? context.fetch(descriptor).first)?.quantity ?? 0
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
    
    func previewCheckout(address: [String: String]? = nil) async throws -> CheckoutPreviewResponse {
        let payload: [String: Any] = [
            "items": items.map { [
                "variant_id": $0.variantId.uuidString.lowercased(),
                "quantity": $0.quantity
            ]},
            "address": address ?? [:]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            throw NetworkError.decodingError
        }
        
        return try await NetworkManager.shared.request(endpoint: "/checkout/preview", method: "POST", body: jsonData)
    }
    
    func placeOrder(address: [String: String]) async throws -> OrderResponse {
        let payload: [String: Any] = [
            "items": items.map { [
                "variant_id": $0.variantId.uuidString.lowercased(),
                "quantity": $0.quantity
            ]},
            "address": address,
            "idempotency_key": idempotencyKey
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
