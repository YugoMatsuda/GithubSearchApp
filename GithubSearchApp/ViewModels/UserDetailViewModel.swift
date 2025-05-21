import Foundation

class UserDetailViewModel: ObservableObject {
    @Published var userDetail: UserDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkService = NetworkService()
    
    func loadUserDetails(username: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let details = try await networkService.getUserDetails(username: username)
                await MainActor.run {
                    self.userDetail = details
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load user details: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}
