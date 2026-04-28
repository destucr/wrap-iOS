import Foundation
import SwiftData

@Model
final class CartItem {
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
}
