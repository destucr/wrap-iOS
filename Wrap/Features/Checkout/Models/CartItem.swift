import Foundation
import SwiftData

@Model
final class CartItem: Hashable, Equatable {
    @Attribute(.unique) var variantId: UUID
    var quantity: Int
    var name: String
    var price: Double
    var addedDate: Date
    
    init(variantId: UUID, name: String, price: Double, quantity: Int = 1) {
        self.variantId = variantId
        self.name = name
        self.price = price
        self.quantity = quantity
        self.addedDate = Date()
    }
    
    static func == (lhs: CartItem, rhs: CartItem) -> Bool {
        return lhs.variantId == rhs.variantId && lhs.quantity == rhs.quantity && lhs.name == rhs.name && lhs.price == rhs.price
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(variantId)
        hasher.combine(quantity)
        hasher.combine(name)
        hasher.combine(price)
    }
}
