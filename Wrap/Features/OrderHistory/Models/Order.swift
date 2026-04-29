import Foundation

// Enums conform to Sendable by default if they don't have associated values
nonisolated enum OrderStatus: String, Codable, Sendable {
    case pending = "PENDING"
    case paid = "PAID"
    case cancelled = "CANCELLED"
}

nonisolated enum DeliveryStatus: String, Codable, Sendable {
    case pending = "PENDING"
    case packing = "PACKING"
    case inTransit = "IN_TRANSIT"
    case delivered = "DELIVERED"
    case failed = "FAILED"
}

nonisolated struct Order: Codable, Sendable {
    let id: UUID
    let userId: UUID
    let totalAmount: Double
    let paymentStatus: OrderStatus
    let deliveryStatus: DeliveryStatus
    let paymentUrl: String?
    let rating: Int?
    let ratingComment: String?
    let createdAt: Date
    let expiresAt: Date?

    nonisolated enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", totalAmount = "total_amount", paymentStatus = "payment_status", deliveryStatus = "delivery_status", paymentUrl = "payment_url", rating, ratingComment = "rating_comment", createdAt = "created_at", expiresAt = "expires_at"
    }
}

nonisolated struct OrderItem: Codable, Sendable {
    let id: UUID
    let productName: String
    let variantName: String
    let quantity: Int
    let priceAtPurchase: Double

    nonisolated enum CodingKeys: String, CodingKey {
        case id, productName = "product_name", variantName = "variant_name", quantity, priceAtPurchase = "price_at_purchase"
    }
}

nonisolated struct OrderDetailResponse: Codable, Sendable {
    let id: UUID
    let totalAmount: Double
    let paymentStatus: OrderStatus
    let deliveryStatus: DeliveryStatus
    let rating: Int?
    let ratingComment: String?
    let createdAt: Date
    let items: [OrderItem]

    nonisolated enum CodingKeys: String, CodingKey {
        case id, totalAmount = "total_amount", paymentStatus = "payment_status", deliveryStatus = "delivery_status", rating, ratingComment = "rating_comment", createdAt = "created_at", items
    }
}
