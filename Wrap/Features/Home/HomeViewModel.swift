import Foundation
import Combine

@MainActor
final class HomeViewModel {
    
    enum Section {
        case banners([PromoBanner])
        case categories([CatalogCategory])
        case products(title: String, items: [Product])
    }
    
    @Published private(set) var sections: [Section] = []
    @Published private(set) var addressText: String = "Mengirim ke..."
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var etaInfo: ETAInfo?
    
    func fetchData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let feedTask = CatalogService.shared.fetchHome()
            async let profileTask = UserService.shared.fetchProfile()
            async let etaTask = CatalogService.shared.fetchETA()
            
            let (fetchedFeed, user, eta) = try await (feedTask, profileTask, etaTask)
            
            self.etaInfo = eta
            
            // Handle Profile/Address
            let address = user.fullAddress ?? user.email
            self.addressText = "Mengirim ke: \(address)"
            
            // Handle Feed Sections
            var newSections: [Section] = []
            if !fetchedFeed.banners.isEmpty {
                newSections.append(.banners(fetchedFeed.banners))
            }
            if !fetchedFeed.categories.isEmpty {
                newSections.append(.categories(fetchedFeed.categories))
            }
            for feedSection in fetchedFeed.sections {
                newSections.append(.products(title: feedSection.title, items: feedSection.items))
            }
            
            self.sections = newSections
        } catch {
            print("HomeViewModel Error: \(error)")
        }
    }
}
