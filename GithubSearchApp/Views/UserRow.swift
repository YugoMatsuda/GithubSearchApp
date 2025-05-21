import SwiftUI

struct UserRow: View {
    let user: User
    @State private var avatarImage: UIImage?
    
    var body: some View {
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
                Text(user.login)
                    .font(.headline)
                
                Text(user.htmlUrl)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .onAppear {
            loadAvatar()
        }
    }
    
    private func loadAvatar() {
        guard avatarImage == nil, let url = URL(string: user.avatarUrl) else { return }
        
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
