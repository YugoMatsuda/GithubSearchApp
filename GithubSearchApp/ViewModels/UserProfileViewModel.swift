import Foundation
import Combine

class UserProfileViewModel: ObservableObject {
    @Published var userDetail: UserDetail?
    @Published var repositories: [Repository] = []
    @Published var isLoadingUser = false
    @Published var isLoadingRepos = false
    @Published var userErrorMessage: String?
    @Published var reposErrorMessage: String?
    
    private let networkService = NetworkService()
    
    func loadUserProfile(username: String) {
        isLoadingUser = true
        userErrorMessage = nil
        
        Task {
            do {
                let details = try await networkService.getUserDetails(username: username)
                await MainActor.run {
                    self.userDetail = details
                    self.isLoadingUser = false
                }
            } catch {
                await MainActor.run {
                    self.handleUserError(error)
                    self.isLoadingUser = false
                }
            }
        }
    }
    
    func loadUserRepositories(username: String) {
        isLoadingRepos = true
        reposErrorMessage = nil
        
        Task {
            do {
                let repos = try await networkService.getUserRepositories(username: username)
                await MainActor.run {
                    self.repositories = repos
                    self.isLoadingRepos = false
                }
            } catch {
                await MainActor.run {
                    // Bug: We're not handling specific error types correctly
                    // Just setting a generic error message
                    self.reposErrorMessage = "Failed to load repositories"
                    self.isLoadingRepos = false
                }
            }
        }
    }
    
    private func handleUserError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .rateLimitExceeded:
                userErrorMessage = "GitHub API rate limit exceeded. Please try again later."
            case .httpError(let code):
                userErrorMessage = "HTTP error: \(code)"
            case .invalidURL:
                userErrorMessage = "Invalid URL"
            case .invalidResponse:
                userErrorMessage = "Invalid response from server"
            case .decodingError:
                userErrorMessage = "Error decoding data"
            case .noData:
                userErrorMessage = "No data received"
            }
        } else {
            userErrorMessage = "Unknown error: \(error.localizedDescription)"
        }
    }
}
