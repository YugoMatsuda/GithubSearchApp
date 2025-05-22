import Foundation
import Combine
import class UIKit.UIImage

enum UserProfileHeaderDisplayResult {
    case success(UserDetail)
    case failure(String)
    case loading
    case initial
}

enum UserProfileRepositoriesDisplayResult {
    case success([Repository])
    case failure(String)
    case loading
    case empty
    case initial
}

class UserProfileViewModel: ObservableObject {
    @Published var userProfileHeaderDisplayResult: UserProfileHeaderDisplayResult = .initial
    @Published var userProfileRepositoriesDisplayResult: UserProfileRepositoriesDisplayResult = .initial

    private let networkService = NetworkService.liveValue
    
    func loadUserProfile(username: String) {
        userProfileHeaderDisplayResult = .loading
        Task {
            do {
                let details = try await networkService.getUserDetails(username)
                await MainActor.run {
                    self.userProfileHeaderDisplayResult = .success(details)
                }
            } catch {
                await MainActor.run {
                    self.userProfileHeaderDisplayResult = .failure(getUserErrorMessage(error))
                }
            }
        }
    }
    
    func loadUserRepositories(username: String) {
        userProfileRepositoriesDisplayResult = .loading
        
        Task {
            do {
                let repos = try await networkService.getUserRepositories(username)
                await MainActor.run {
                    self.userProfileRepositoriesDisplayResult = .success(repos)
                }
            } catch {
                await MainActor.run {
                    // Bug: We're not handling specific error types correctly
                    // Just setting a generic error message
                    self.userProfileHeaderDisplayResult = .failure(getUserErrorMessage(error))
                }
            }
        }
    }
    
    private func getUserErrorMessage(_ error: Error) -> String {
        let userErrorMessage: String
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
        return userErrorMessage
    }
}
