import Foundation

struct CheckoutPreviewItem: Codable, Sendable {
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

struct CheckoutPreviewResponse: Codable, Sendable {
    let isValid: Bool
    let subtotal: Double
    let deliveryFee: Double
    let total: Double
    let items: [CheckoutPreviewItem]

    enum CodingKeys: String, CodingKey {
        case isValid = "is_valid"
        case subtotal
        case deliveryFee = "delivery_fee"
        case total, items
    }
}
