import Foundation

struct Product: Codable {
    let id: UUID
    let name: String
    let slug: String
    let description: String?
    let basePrice: Double
    let images: [String]?
    let tags: [String]?
    let categoryId: UUID?
    let unitOfMeasure: String?
    let weightLabel: String?
    let temperatureControl: String?
    let variants: [ProductVariant]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, slug, description, tags, images, variants
        case basePrice = "base_price"
        case categoryId = "category_id"
        case unitOfMeasure = "unit_of_measure"
        case weightLabel = "weight_label"
        case temperatureControl = "temperature_control"
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

struct Banner: Codable {
    let id: UUID
    let imageUrl: String
    let actionUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case imageUrl = "image_url"
        case actionUrl = "action_url"
    }
}

struct Category: Codable {
    let id: UUID
    let name: String
    let iconUrl: String?
    let priority: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name, priority
        case iconUrl = "icon_url"
    }
}

struct FeedSection: Codable {
    let title: String
    let type: String // "standard", "flash_sale", "personalized"
    let items: [Product]
}

struct HomeFeedResponse: Codable {
    let banners: [Banner]
    let categories: [Category]
    let sections: [FeedSection]
}
