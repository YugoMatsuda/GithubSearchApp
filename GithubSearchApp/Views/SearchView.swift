import CasePaths
import ComposableArchitecture
import SwiftUI

@Reducer
struct Search {
    @ObservableState
    struct State: Equatable {
        var displayResult: DisplayResult
        var path: [User] = []
        var mode: Mode = .search
        var searchText = ""
    }
    
    @CasePathable
    enum Action: BindableAction {
        case view(ViewAction)
        case binding(BindingAction<State>)
        case `internal`(InternalAction)
        case searchBody(SearchBody.Action)

        @CasePathable
        enum ViewAction: Equatable {
            case didTapSeachClearButton
            
        }
        
        @CasePathable
        enum InternalAction {
            case searchTextChangeDebounced
            case didReceiveSearchResult(TaskResult<[User]>)
        }
    }
    
    @Dependency(\.networkService) var networkService
    @Dependency(\.userDefaultsService) var userDefaultsService
    @Dependency(\.mainQueue) var mainQueue

    private enum CancelID {
      case response
    }
            
    var body: some Reducer<State, Action> {
        BindingReducer()
        Scope(state: \.displayResult, action: \.self) {
            Scope(state: \.success, action: \.searchBody) {
                SearchBody()
            }
        }
        Reduce { state, action in
            switch action {
            case .view(.didTapSeachClearButton):
                state.searchText = ""
                state.displayResult = .initial
                return .none
            case .binding(\.mode):
                state.displayResult = makeDisplayResultFromMemoryCache(
                    from: state.displayResult,
                    mode: state.mode
                )
                return .none
            case .binding(\.searchText):
              return .run { send in
                  await send(.internal(.searchTextChangeDebounced))
              }
              .debounce(
                id: CancelID.response,
                for: .seconds(0.5),
                scheduler: mainQueue
              )
            case .internal(.searchTextChangeDebounced):
                guard !state.searchText.isEmpty else {
                    state.displayResult = .initial
                  return .none
                }
                state.displayResult = .loading
                return .run { [query = state.searchText] send in
                    await send(
                        .internal(
                            .didReceiveSearchResult(
                                TaskResult { try await networkService.searchUsers(query)  }
                            )
                        ),
                        animation: .default
                    )
                }
            case .internal(.didReceiveSearchResult(.success(let users))):
                state.displayResult = makeDisplayResult(
                    users: users,
                    mode: state.mode
                )
                return .none
            case .internal(.didReceiveSearchResult(.failure(let error))):
                state.displayResult = .failure("Error: \(error.localizedDescription)")
                return .none
            case .searchBody(.favoriteList(.delegate(.didTapListRow(let user)))),
                 .searchBody(.searchList(.delegate(.didTapListRow(let user)))):
                state.path.append(
                    user
                )
                return .none
            case .searchBody:
                return .none
            case .binding:
                return .none
            }
        }
    }
    
    private func makeDisplayResultFromMemoryCache(
        from displayResult:  Search.State.DisplayResult,
        mode: Search.State.Mode
    ) -> Search.State.DisplayResult {
        guard case .success(let state) = displayResult else {
            switch mode {
            case .search:
                return .initial
            case .favorites:
                return makeDisplayResult(
                    users: [],
                    mode: mode
                )
            }
        }
        let favoriteUsers = userDefaultsService.getFavoriteUsers()
        
        // Restore from search list 
        return .success(
            SearchBody.State.init(
                mode: mode,
                searchList: SearchList.State.init(
                    items: .init(
                        uniqueElements: state.searchList.items.map { user in
                            UserRow.State.init(
                                user: user.user,
                                isFavorite: favoriteUsers.contains( where: { $0.id == user.user.id })
                            )
                        }
                    )
                ),
                favoriteList: makeFavoriteListState(favoriteUsers)
            )
        )
    }
    
    private func makeDisplayResult(
        users: [User],
        mode: Search.State.Mode
    ) -> Search.State.DisplayResult {
        let favoriteUsers = userDefaultsService.getFavoriteUsers()
        return .success(
            SearchBody.State.init(
                mode: mode,
                searchList: SearchList.State.init(
                    items: .init(
                        uniqueElements: users.map { user in
                            UserRow.State.init(
                                user: user,
                                isFavorite: favoriteUsers.contains( where: { $0.id == user.id })
                            )
                        }
                    )
                ),
                favoriteList: makeFavoriteListState(favoriteUsers)
            )
        )
    }
    
    private func makeFavoriteListState(_ favoriteUsers: [User]) -> FavoriteList.State {
        FavoriteList.State.init(
            items: .init(
                uniqueElements: favoriteUsers.map { user in
                    UserRow.State.init(
                        user: user,
                        isFavorite: true
                    )
                }
            )
        )
    }
        
}

extension Search.State {
    @CasePathable
    @dynamicMemberLookup
    enum DisplayResult: Equatable {
        case success(SearchBody.State)
        case failure(String)
        case loading
        case initial
    }
    
    enum Mode: String, Identifiable, CaseIterable, Equatable {
        case search
        case favorites
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .search:
                return "Search"
            case .favorites:
                return "Favorites"
            }
        }
    }
}


struct SearchView: View {
    @Bindable var store: StoreOf<Search>

    var body: some View {
        NavigationStack(path: $store.path) {
            VStack {
                Picker("Mode", selection: $store.mode) {
                    ForEach(Search.State.Mode.allCases) { mode in
                        Text(mode.title)
                            .tag(mode)
                            
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                if case .search = store.mode {
                    searchBarView
                }
                
                switch store.displayResult {
                case .success:
                    if let bodyStore = store.scope(state: \.displayResult.success, action: \.searchBody) {
                        SearchBodyView(store: bodyStore)
                    }
                case .failure(let errorMessage):
                    failureView(errorMessage)
                case .loading:
                    loadingView
                case .initial:
                    initialView
                }
            }
            .navigationTitle("GitHub Search")
            .navigationDestination(for: User.self) { user in
                UserProfileView(username: user.login)
            }
        }
    }
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search GitHub users...", text: $store.searchText)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !store.searchText.isEmpty {
                Button(action: {
                    store.send(.view(.didTapSeachClearButton), animation: .default)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private func failureView(_ errorMessage: String) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
                .padding()
            
            Text(errorMessage)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(maxHeight: .infinity)
    }
    
    private var loadingView: some View {
        Group {
            Spacer()
            ProgressView("Searching...")
            Spacer()
        }
    }
    
    private var initialView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Search for GitHub users")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxHeight: .infinity)
    }
}
