import SwiftUI
import ComposableArchitecture

@Reducer
struct UserRow {
    @ObservableState
    struct State: Equatable, Identifiable {
        var id: Int {
            user.id
        }
        var user: User
        var isFavorite: Bool
            
    }
    
    enum Action: BindableAction {
        case view(ViewAction)
        case delegate(DelegateAction)
        case binding(BindingAction<State>)

        enum ViewAction {
            case didTap
            case didTapFavorite
        }
        
        enum DelegateAction {
            case didTapRow(id: Int)
            case didTapFavoriteButton(id: Int)
        }
        
    }
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .view(.didTap):
                return .send(.delegate(.didTapRow(id: state.user.id)))
            case .view(.didTapFavorite):
                return .send(.delegate(.didTapFavoriteButton(id: state.user.id)))
            case .delegate:
                return .none
            case .binding:
                return .none
            }
        }
    }
}


struct UserRowView: View {
    @Bindable var store: StoreOf<UserRow>

    var body: some View {
        HStack {
            HStack(spacing: 12) {
                // Avatar image
                AsyncImage(url: URL(string: store.user.avatarUrl)) { phase in
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
                        Image(systemName: "person.circle")
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
                    Text(store.user.login)
                        .font(.headline)
                    
                    Text(store.user.htmlUrl)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture {
                store.send(.view(.didTap))
            }
            
            
            Button(action: {
                store.send(.view(.didTapFavorite), animation: .default)
            }) {
                Image(systemName: store.isFavorite ? "star.fill" : "star")
                    .foregroundColor(store.isFavorite ? .yellow : .gray)
                    .font(.title2)
                    .contentShape(Rectangle())
            }
            .frame(width: 50, height: 50)
        }
    }
}
