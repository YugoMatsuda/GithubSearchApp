import CasePaths
import ComposableArchitecture
import SwiftUI

@Reducer
struct FavoriteList {
    @ObservableState
    struct State: Equatable {
        var items: IdentifiedArrayOf<UserRow.State>
    }
    
    @CasePathable
    enum Action: BindableAction {
        case view(ViewAction)
        case delegate(DelegateAction)
        case binding(BindingAction<State>)
        case items(IdentifiedActionOf<UserRow>)

        @CasePathable
        enum ViewAction: Equatable {
        }
        
        @CasePathable
        enum DelegateAction: Equatable {
            case didTapListRow(user: User)
        }
    }
    
    @Dependency(\.userDefaultsService) var userDefaultsService
        
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .view:
                return .none
            case .binding:
                return .none
            case .delegate:
              return .none
            case .items(.element(_, .delegate(.didTapRow(id: let id)))):
                guard let user = state.items[id: id]?.user else { return .none }
                return .send(.delegate(.didTapListRow(user: user)))
            case .items(.element(_, .delegate(.didTapFavoriteButton(id: let id)))):
                state.items = state.items.filter { item in
                    item.id != id
                }
                userDefaultsService.saveFavoriteUser(state.items.map(\.user))
                return .none
            case .items:
                return .none
            }
        }
        .forEach(\.items, action: \.items) {
            UserRow()
        }
    }
}

struct FavoriteListView: View {
    @Bindable var store: StoreOf<FavoriteList>

    var body: some View {
        if store.items.isEmpty {
            emptyView
        } else {
            List {
                ForEach(
                    store.scope(
                        state: \.items,
                        action: \.items
                    ),
                    content: UserRowView.init(store:)
                )
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No users found")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxHeight: .infinity)
    }
}
