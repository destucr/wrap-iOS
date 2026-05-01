import Foundation

// MARK: - Core Models
// Added 'nonisolated' to ensure background threads can decode these safely in Swift 6

nonisolated struct Product: Codable, Sendable, Hashable, Equatable {
    let id: UUID
    let name: String
    let slug: String
    let description: String?
    let brand: String?
    let isHalal: Bool?
    let basePrice: Double
    let images: [String]?
    let tags: [String]?
    let categoryId: UUID?
    let unitOfMeasure: String?
    let weightLabel: String?
    let temperatureControl: String?
    let variants: [ProductVariant]?

    nonisolated enum CodingKeys: String, CodingKey {
        case id, name, slug, description, brand, tags, images, variants
        case isHalal = "is_halal"
        case basePrice = "base_price"
        case categoryId = "category_id"
        case unitOfMeasure = "unit_of_measure"
        case weightLabel = "weight_label"
        case temperatureControl = "temperature_control"
    }
}

nonisolated struct ProductVariant: Codable, Sendable, Hashable, Equatable {
    let id: UUID
    let productId: UUID
    let sku: String
    let name: String?
    let priceOverride: Double?
    let qtyOnHand: Int
    let weightGrams: Int?

    nonisolated enum CodingKeys: String, CodingKey {
        case id, name, sku
        case productId = "product_id"
        case priceOverride = "price_override"
        case qtyOnHand = "qty_on_hand"
        case weightGrams = "weight_grams"
    }
}

// MARK: - Catalog & Home Models

nonisolated struct PromoBanner: Codable, Sendable, Hashable, Equatable {
    let id: UUID
    let imageUrl: String
    let actionUrl: String?

    nonisolated enum CodingKeys: String, CodingKey {
        case id
        case imageUrl = "image_url"
        case actionUrl = "action_url"
    }
}

nonisolated struct CatalogCategory: Codable, Sendable, Hashable, Equatable {
    let id: UUID
    let name: String
    let iconUrl: String?
    let priority: Int

    nonisolated enum CodingKeys: String, CodingKey {
        case id, name, priority
        case iconUrl = "icon_url"
    }
}

nonisolated struct HomeFeedSection: Codable, Sendable, Hashable, Equatable {
    let title: String
    let type: String // "standard", "flash_sale", "personalized"
    let items: [Product]
}

nonisolated struct HomeFeedData: Codable, Sendable, Hashable, Equatable {
    let banners: [PromoBanner]
    let categories: [CatalogCategory]
    let sections: [HomeFeedSection]
}
