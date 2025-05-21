import SwiftUI

struct UserDetailView: View {
    let username: String
    @StateObject private var viewModel = UserDetailViewModel()
    @State private var avatarImage: UIImage?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                if viewModel.isLoading {
                    ProgressView("Loading user details...")
                        .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                            .padding()
                        
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Retry") {
                            viewModel.loadUserDetails(username: username)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if let userDetail = viewModel.userDetail {
                    // Avatar
                    if let avatarImage = avatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 120, height: 120)
                    }
                    
                    // Name and username
                    VStack(spacing: 4) {
                        if let name = userDetail.name {
                            Text(name)
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        
                        Text("@\(userDetail.login)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Bio
                    if let bio = userDetail.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Stats
                    HStack(spacing: 30) {
                        VStack {
                            Text("\(userDetail.publicRepos)")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("Repos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(userDetail.followers)")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("Followers")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(userDetail.following)")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("Following")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // View Profile Button - Added to navigate to the new UserProfileView
                    NavigationLink(destination: UserProfileView(username: username)) {
                        Text("View Full Profile")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.top, 20)
                }
            }
            .padding()
        }
        .navigationTitle(username)
        .onAppear {
            viewModel.loadUserDetails(username: username)
            loadAvatar()
        }
    }
    
    private func loadAvatar() {
        guard let userDetail = viewModel.userDetail,
              let url = URL(string: userDetail.avatarUrl) else { return }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.avatarImage = image
                    }
                }
            } catch {
                print("Failed to load avatar: \(error)")
            }
        }
    }
}
