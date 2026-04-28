import Foundation

struct Product: Codable {
    let id: UUID
    let name: String
    let slug: String
    let description: String?
    let basePrice: Double
    let images: [String]?
    let tags: [String]?
    let variants: [ProductVariant]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, slug, description, tags, images, variants
        case basePrice = "base_price"
    }
}

struct ProductVariant: Codable {
    let id: UUID
    let productId: UUID
    let sku: String
    let name: String?
    let priceOverride: Double?
    let qtyOnHand: Int
    let weightGrams: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, name, sku
        case productId = "product_id"
        case priceOverride = "price_override"
        case qtyOnHand = "qty_on_hand"
        case weightGrams = "weight_grams"
    }
}
