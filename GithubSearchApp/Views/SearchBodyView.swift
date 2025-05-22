import CasePaths
import ComposableArchitecture
import SwiftUI

@Reducer
struct SearchBody {
    @ObservableState
    struct State: Equatable {
        let mode: Search.State.Mode
        var searchList: SearchList.State
        var favoriteList: FavoriteList.State
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case searchList(SearchList.Action)
        case favoriteList(FavoriteList.Action)
        case delegate(DelegateAction)
        
        enum DelegateAction {
            case didTapListRow(user: User)
        }
    }
    
    @Dependency(\.userDefaultsService) var userDefaultsService
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Scope(state: \.searchList, action: \.searchList) {
            SearchList()
        }
        Scope(state: \.favoriteList, action: \.favoriteList) {
            FavoriteList()
        }
        Reduce { state, action in
            switch action {
            case .delegate:
                return .none
            case .binding:
                return .none
            case .searchList(.delegate(.didTapListRow(let user))):
                return .send(.delegate(.didTapListRow(user: user)))
            case .searchList(.delegate(.didTapFavoriteButton(let user))):
                var favoriteUsers = state.favoriteList.items.map { $0.user }
                if favoriteUsers.contains(where: { $0.id == user.id }) {
                    favoriteUsers = favoriteUsers.filter { $0.id != user.id }
                } else {
                    favoriteUsers.append(user)
                }
                userDefaultsService.saveFavoriteUser(favoriteUsers)
                return .none
            case .favoriteList(.delegate(.didTapListRow(let user))):
                return .send(.delegate(.didTapListRow(user: user)))
            case .searchList:
                return .none
            case .favoriteList:
                return .none
            }
        }
    }
}

struct SearchBodyView: View {
    @Bindable var store: StoreOf<SearchBody>

    var body: some View {
        switch store.mode {
        case .search:
            SearchListView(store: store.scope(state: \.searchList, action: \.searchList))
        case .favorites:
            FavoriteListView(store: store.scope(state: \.favoriteList, action: \.favoriteList))
        }
    }
}
