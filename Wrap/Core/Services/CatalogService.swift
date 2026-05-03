import Foundation

@MainActor
class CatalogService {
    static let shared = CatalogService()
    private init() {}
    
    func fetchHome() async throws -> HomeFeedData {
        return try await NetworkManager.shared.request(endpoint: "/catalog/home")
    }
    
    func fetchProducts(categoryId: UUID? = nil) async throws -> [Product] {
        var endpoint = "/catalog/products"
        if let categoryId = categoryId {
            endpoint += "?category_id=\(categoryId.uuidString.lowercased())"
        }
        return try await NetworkManager.shared.request(endpoint: endpoint)
    }
    
    func searchProducts(query: String) async throws -> [Product] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return try await NetworkManager.shared.request(endpoint: "/catalog/search?q=\(encodedQuery)")
    }
    
    func fetchProductDetail(id: UUID) async throws -> Product {
        return try await NetworkManager.shared.request(endpoint: "/catalog/detail/\(id.uuidString.lowercased())")
    }
    
    func fetchETA() async throws -> ETAInfo {
        return try await NetworkManager.shared.request(endpoint: "/logistics/eta")
    }
    
    func fetchStock(variantId: UUID) async throws -> Int {
        let resp: [String: Int] = try await NetworkManager.shared.request(endpoint: "/catalog/stock/\(variantId.uuidString.lowercased())")
        return resp["qty"] ?? 0
    }
}
