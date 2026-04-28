import Foundation
import SwiftData
import UIKit

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
    
    // MARK: - Sync Logic
    func syncWithBackend(completion: @escaping (Bool) -> Void) {
        guard !isSyncing else { return }
        isSyncing = true
        
        let payload: [String: Any] = [
            "items": items.map { [
                "variant_id": $0.variantId.uuidString.lowercased(),
                "quantity": $0.quantity
            ]}
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            isSyncing = false
            completion(false)
            return
        }
        
        NetworkManager.shared.request(endpoint: "/user/cart/sync", method: "POST", body: jsonData) { [weak self] (result: Result<[String: String], NetworkError>) in
            self?.isSyncing = false
            switch result {
            case .success:
                completion(true)
            case .failure:
                completion(false)
            }
        }
    }
    
    func placeOrder(address: [String: String], completion: @escaping (Result<[String: String], NetworkError>) -> Void) {
        let payload: [String: Any] = [
            "items": items.map { [
                "variant_id": $0.variantId.uuidString.lowercased(),
                "quantity": $0.quantity
            ]},
            "address": address
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            completion(.failure(.decodingError))
            return
        }
        
        NetworkManager.shared.request(endpoint: "/checkout/place", method: "POST", body: jsonData) { (result: Result<[String: String], NetworkError>) in
            completion(result)
        }
    }
}

extension NSNotification.Name {
    static let cartUpdated = NSNotification.Name("cartUpdated")
}
