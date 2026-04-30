import Foundation
import SwiftData
import UIKit
import RxSwift
import RxRelay

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

nonisolated struct CartItemResponse: Codable, Sendable {
    let variantId: UUID
    let quantity: Int
    let name: String
    let price: Double
    
    nonisolated enum CodingKeys: String, CodingKey {
        case variantId = "variant_id"
        case quantity, name, price
    }
}

nonisolated struct CartResponse: Codable, Sendable {
    let items: [CartItemResponse]
}

@MainActor
class CartManager: Sendable {
    static let shared = CartManager()
    
    private var context: ModelContext?
    private var isSyncing = false
    private var _idempotencyKey: String?
    
    // RxSwift Infrastructure
    private let disposeBag = DisposeBag()
    private let itemsRelay = BehaviorRelay<[CartItem]>(value: [])
    
    var cartItems: Observable<[CartItem]> {
        return itemsRelay.asObservable()
    }
    
    private init() {
        setupSyncSubscription()
    }
    
    func setup(context: ModelContext) {
        self.context = context
        refreshRelay()
    }

    private func setupSyncSubscription() {
        cartItems
            .skip(1) // Skip initial value
            .debounce(.seconds(2), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                Task {
                    try? await self?.syncWithBackend()
                }
            })
            .disposed(by: disposeBag)
    }

    private func refreshRelay() {
        itemsRelay.accept(items)
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
            refreshRelay()
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
    func fetchCart() async throws {
        let response: CartResponse = try await NetworkManager.shared.request(endpoint: "/user/cart")
        
        guard let context = context else { return }
        
        // Clear local first
        try? context.delete(model: CartItem.self)
        
        // Insert new ones
        for it in response.items {
            let newItem = CartItem(variantId: it.variantId, name: it.name, price: it.price, quantity: it.quantity)
            context.insert(newItem)
        }
        
        saveAndNotify()
    }

    func syncWithBackend() async throws {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        
        try await CheckoutService.shared.syncCart(items: items)
    }
    
    func previewCheckout(address: [String: String]? = nil) async throws -> CheckoutPreviewResponse {
        return try await CheckoutService.shared.previewCheckout(items: items, address: address)
    }
    
    func placeOrder(address: [String: String]) async throws -> OrderResponse {
        return try await CheckoutService.shared.placeOrder(items: items, address: address, idempotencyKey: idempotencyKey)
    }
}

extension NSNotification.Name {
    static let cartUpdated = NSNotification.Name("cartUpdated")
}
