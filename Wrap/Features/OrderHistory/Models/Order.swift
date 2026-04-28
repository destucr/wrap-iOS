import Foundation

enum OrderStatus: String, Codable {
    case pending = "PENDING"
    case paid = "PAID"
    case cancelled = "CANCELLED"
}

enum DeliveryStatus: String, Codable {
    case pending = "PENDING"
    case packing = "PACKING"
    case inTransit = "IN_TRANSIT"
    case delivered = "DELIVERED"
    case failed = "FAILED"
}

struct Order: Codable {
    let id: UUID
    let userId: UUID
    let totalAmount: Double
    let paymentStatus: OrderStatus
    let deliveryStatus: DeliveryStatus
    let paymentUrl: String?
    let createdAt: Date
    let expiresAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", totalAmount = "total_amount", paymentStatus = "payment_status", deliveryStatus = "delivery_status", paymentUrl = "payment_url", createdAt = "created_at", expiresAt = "expires_at"
    }
}
