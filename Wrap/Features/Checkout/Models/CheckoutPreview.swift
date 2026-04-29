import Foundation

// 1. Mark the struct as nonisolated to break the MainActor default
nonisolated struct CheckoutPreviewItem: Sendable {
    let variantId: UUID
    let productName: String
    let variantName: String
    let sku: String
    let quantity: Int
    let price: Double
    let subtotal: Double
    let isAvailable: Bool
    let currentQty: Int
    let message: String?
}

// 2. Explicitly conform to Codable outside the main actor scope
extension CheckoutPreviewItem: nonisolated Codable {
    enum CodingKeys: String, CodingKey {
        case variantId = "variant_id"
        case productName = "product_name"
        case variantName = "variant_name"
        case sku, quantity, price, subtotal
        case isAvailable = "is_available"
        case currentQty = "current_qty"
        case message
    }
}

// Repeat for the main Response struct
nonisolated struct CheckoutPreviewResponse: Sendable {
    let isValid: Bool
    let subtotal: Double
    let deliveryFee: Double
    let serviceFee: Double
    let total: Double
    let items: [CheckoutPreviewItem]
}

extension CheckoutPreviewResponse: nonisolated Codable {
    enum CodingKeys: String, CodingKey {
        case isValid = "is_valid"
        case subtotal
        case deliveryFee = "delivery_fee"
        case serviceFee = "service_fee"
        case total, items
    }
}
