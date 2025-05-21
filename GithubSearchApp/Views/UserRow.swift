import SwiftUI

struct UserRow: View {
    let userRowUIModel: UserRowUIModel
    @State private var avatarImage: UIImage?
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                // Avatar image
                if let avatarImage = avatarImage {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            ProgressView()
                        )
                }
                
                // User info
                VStack(alignment: .leading, spacing: 4) {
                    Text(userRowUIModel.login)
                        .font(.headline)
                    
                    Text(userRowUIModel.htmlUrl)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
            .onTapGesture {
                userRowUIModel.didTapRow(userRowUIModel.id)
            }
            
            Spacer()
            
            Button(action: {
                userRowUIModel.didTapFavoriteButton(userRowUIModel.id)
            }) {
                Image(systemName: userRowUIModel.isFavorite ? "star.fill" : "star")
                    .foregroundColor(userRowUIModel.isFavorite ? .yellow : .gray)
                    .font(.title2)
            }
        }
        .onAppear {
            loadAvatar()
        }

    }
    
    private func loadAvatar() {
        guard avatarImage == nil, let url = URL(string: userRowUIModel.avatarUrl) else { return }
        
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

extension UserRow {
    struct UserRowUIModel: Identifiable {
        let id: Int
        let login: String
        let htmlUrl: String
        let avatarUrl: String
        let isFavorite: Bool
        let didTapFavoriteButton: (Int) -> Void
        let didTapRow: (Int) -> Void
    }
}
