import SwiftUI
import ComposableArchitecture

@Reducer
struct UserProfile {
    @ObservableState
    struct State: Equatable {
        let userName: String
        var userProfileHeaderDisplayResult: UserProfileHeaderDisplayResult
        var userProfileRepositoriesDisplayResult: UserProfileRepositoriesDisplayResult
        
        enum UserProfileHeaderDisplayResult: Equatable {
            case success(UserDetail)
            case failure(String)
            case loading
            case initial
        }

        enum UserProfileRepositoriesDisplayResult: Equatable {
            case success([Repository])
            case failure(String)
            case loading
            case empty
            case initial
        }
    }
    
    @CasePathable
    enum Action: BindableAction {
        case view(ViewAction)
        case binding(BindingAction<State>)
        case `internal`(InternalAction)

        @CasePathable
        enum ViewAction {
            case onAppear
            case didTapRetryFetchUserDetailButton
            case didTapRetryFetchRepositoriesButton
        }
        
        @CasePathable
        enum InternalAction {
            case didReceiveUserDetailResult(TaskResult<UserDetail>)
            case didReceiveRepositorieslResult(TaskResult<[Repository]>)
        }
    }
    
    @Dependency(\.networkService) var networkService
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                state.userProfileHeaderDisplayResult = .loading
                state.userProfileRepositoriesDisplayResult = .loading
                return .merge(
                    fetchUserDetail(state: &state),
                    fetchRepositories(state: &state)
                )
            case .view(.didTapRetryFetchUserDetailButton):
                state.userProfileHeaderDisplayResult = .loading
                return fetchUserDetail(state: &state)
            case .view(.didTapRetryFetchRepositoriesButton):
                state.userProfileRepositoriesDisplayResult = .loading
                return fetchRepositories(state: &state)
            case .internal(.didReceiveUserDetailResult(.success(let userDetail))):
                state.userProfileHeaderDisplayResult = .success(userDetail)
                return .none
            case .internal(.didReceiveUserDetailResult(.failure(let error))):
                state.userProfileHeaderDisplayResult = .failure(getUserErrorMessage(error))
                return .none
            case .internal(.didReceiveRepositorieslResult(.success(let repositories))):
                if repositories.isEmpty {
                    state.userProfileRepositoriesDisplayResult = .empty
                } else {
                    state.userProfileRepositoriesDisplayResult = .success(repositories)
                }
                return .none
            case .internal(.didReceiveRepositorieslResult(.failure(let error))):
                state.userProfileRepositoriesDisplayResult = .failure(getUserErrorMessage(error))
                return .none
            case .internal:
                return .none
            case .binding:
                return .none
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
    
    
    private func fetchUserDetail(state: inout State) -> Effect<Action> {
        return  .run { [username = state.userName] send in
            await send(
                .internal(
                    .didReceiveUserDetailResult(
                        TaskResult { try await networkService.getUserDetails(username)  }
                    )
                ),
                animation: .default
            )
        }
    }
    
    private func fetchRepositories(state: inout State) -> Effect<Action> {
        .run { [username = state.userName] send in
            await send(
                .internal(
                    .didReceiveRepositorieslResult(
                        TaskResult { try await networkService.getUserRepositories(username)  }
                    )
                ),
                animation: .default
            )
        }
    }
}

struct UserProfileView: View {
    @Bindable var store: StoreOf<UserProfile>

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 16) {
                switch store.userProfileHeaderDisplayResult {
                case .success(let userDetail):
                    AsyncImage(url: URL(string: userDetail.avatarUrl)) { phase in
                        switch phase {
                        case .empty:
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 200, height: 200)
                                .overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .frame(width: 200, height: 200)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        case .failure(_):
                            Image(systemName: "user")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        @unknown default:
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 200, height: 200)
                                .overlay(ProgressView())
                        }
                    }
                    
                    VStack(spacing: 8) {
                        if let name = userDetail.name {
                            Text(name)
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        
                        Text("@\(userDetail.login)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if let bio = userDetail.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.top, 4)
                        }
                    }
                    
                    // Stats
                    HStack(spacing: 30) {
                        StatView(value: userDetail.publicRepos, label: "Repos")
                        StatView(value: userDetail.followers, label: "Followers")
                        StatView(value: userDetail.following, label: "Following")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                case .failure(let errorMessage):
                    ErrorView(message: errorMessage) {
                        store.send(.view(.didTapRetryFetchUserDetailButton), animation: .default)
                    }
                case .loading:
                    ProgressView("Loading profile...")
                        .padding()
                case .initial:
                    EmptyView()
                }
                
                // Repositories Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Repositories")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top)
                    switch store.userProfileRepositoriesDisplayResult {
                    case .success(let repositories):
                        ForEach(repositories) { repo in
                            RepositoryRow(repository: repo)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                        }
                    case .failure(let errorMessage):
                        VStack {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding()
                            
                            Button("Retry") {
                                store.send(.view(.didTapRetryFetchRepositoriesButton), animation: .default)

                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                    case .loading:
                        HStack {
                            Spacer()
                            ProgressView("Loading repositories...")
                            Spacer()
                        }
                        .padding()
                    case .empty:
                        Text("No repositories found")
                            .foregroundColor(.secondary)
                            .padding()
                    case .initial:
                        EmptyView()
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
            .onAppear {
                store.send(.view(.onAppear), animation: .default)
            }
        }
    }
}

struct StatView: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack {
            Text("\(value)")
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct RepositoryRow: View {
    let repository: Repository
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(repository.name)
                .font(.headline)
            
            if let description = repository.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                if let language = repository.language {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(languageColor(for: language))
                            .frame(width: 12, height: 12)
                        Text(language)
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("\(repository.stargazersCount)")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func languageColor(for language: String) -> Color {
        switch language.lowercased() {
        case "swift": return .orange
        case "javascript": return .yellow
        case "python": return .blue
        case "java": return .red
        case "kotlin": return .purple
        case "c#": return .green
        case "typescript": return .blue
        default: return .gray
        }
    }
}

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Retry") {
                retryAction()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .padding()
    }
}
