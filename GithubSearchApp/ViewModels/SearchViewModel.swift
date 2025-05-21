import Foundation
import Combine

class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasSearched = false
    
    private let networkService = NetworkService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $searchText
            .removeDuplicates()
            .filter { !$0.isEmpty }
            .sink { [weak self] query in
                self?.searchUsers(query: query)
            }
            .store(in: &cancellables)
    }
    
    func searchUsers(query: String) {
        guard !query.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        hasSearched = true
        
        Task {
            do {
                let users = try await networkService.searchUsers(query: query)
                
                await MainActor.run {
                    self.users = users
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.users = []
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}
