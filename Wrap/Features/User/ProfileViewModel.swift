import Foundation
import Combine

enum ViewState<T>: Equatable where T: Equatable {
    case idle
    case loading
    case success(T)
    case error(String)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    static func == (lhs: ViewState<T>, rhs: ViewState<T>) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.loading, .loading): return true
        case (.success(let l), .success(let r)): return l == r
        case (.error(let l), .error(let r)): return l == r
        default: return false
        }
    }
}

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var state: ViewState<UserData> = .idle
    private var cancellables = Set<AnyCancellable>()
    
    func fetchProfile() {
        state = .loading
        Task {
            do {
                let user = try await UserService.shared.fetchProfile()
                state = .success(user)
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }
}
