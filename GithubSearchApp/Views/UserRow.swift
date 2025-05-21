import SwiftUI

struct UserRow: View {
    let userRowUIModel: UserRowUIModel

    var body: some View {
        HStack {
            HStack(spacing: 12) {
                // Avatar image
                AsyncImage(url: URL(string: userRowUIModel.avatarUrl)) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .overlay(
                                ProgressView()
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    case .failure(_):
                        Image(systemName: "user")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    @unknown default:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .overlay(
                                ProgressView()
                            )
                    }
                }
                
                // User info
                VStack(alignment: .leading, spacing: 4) {
                    Text(userRowUIModel.login)
                        .font(.headline)
                    
                    Text(userRowUIModel.htmlUrl)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture {
                userRowUIModel.didTapRow()
            }
            
            
            Button(action: {
                userRowUIModel.didTapFavoriteButton(userRowUIModel.id)
            }) {
                Image(systemName: userRowUIModel.isFavorite ? "star.fill" : "star")
                    .foregroundColor(userRowUIModel.isFavorite ? .yellow : .gray)
                    .font(.title2)
                    .contentShape(Rectangle())
            }
            .frame(width: 50, height: 50)
        }
    }
}

extension UserRow {
    struct UserRowUIModel: Identifiable, Equatable {
        var id: Int
        var login: String
        var htmlUrl: String
        var avatarUrl: String
        var isFavorite: Bool
        
        @EquatableNoop
        var didTapFavoriteButton: (Int) -> Void
        @EquatableNoop
        var didTapRow: () -> Void
    }
}
