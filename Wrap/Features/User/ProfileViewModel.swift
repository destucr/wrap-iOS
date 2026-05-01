import Foundation
import Combine

enum ViewState<T> {
    case idle
    case loading
    case success(T)
    case error(String)
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
