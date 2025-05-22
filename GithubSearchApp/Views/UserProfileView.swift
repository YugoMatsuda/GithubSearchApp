import SwiftUI

struct UserProfileView: View {
    let username: String
    @StateObject private var viewModel = UserProfileViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 16) {
                switch viewModel.userProfileHeaderDisplayResult {
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
                        viewModel.loadUserProfile(username: username)
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
                    switch viewModel.userProfileRepositoriesDisplayResult {
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
                                viewModel.loadUserRepositories(username: username)
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
                viewModel.loadUserProfile(username: username)
                viewModel.loadUserRepositories(username: username)
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
