import CasePaths
import ComposableArchitecture
import SwiftUI

@Reducer
struct Search {
    @ObservableState
    struct State: Equatable {
        var displayResult: DisplayResult
        var searchResultUsers: [User]? = nil
        var favoriteUsers: [User]
        var path: [User] = []
        var mode: Mode = .search
        var searchText = ""
    }
    
    @CasePathable
    enum Action: BindableAction {
        case view(ViewAction)
        case binding(BindingAction<State>)
        case `internal`(InternalAction)

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
        Reduce { state, action in
            switch action {
            case .view(.didTapSeachClearButton):
                state.searchText = ""
                state.searchResultUsers = nil
                state.displayResult = .initial
                return .none
            case .binding(\.mode):
                state.displayResult = makeDisplayResult(
                    users:  state.searchResultUsers,
                    favoriteUsers: state.favoriteUsers,
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
                    state.searchResultUsers = nil
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
                state.searchResultUsers = users
                state.displayResult = makeDisplayResult(
                    users:  state.searchResultUsers ,
                    favoriteUsers: state.favoriteUsers,
                    mode: state.mode
                )
                return .none
            case .internal(.didReceiveSearchResult(.failure(let error))):
                state.displayResult = .failure("Error: \(error.localizedDescription)")
                return .none
            case .binding:
                return .none
            case .internal:
                return .none
            }
        }
    }
    
    private func makeDisplayResult(
        users: [User]?,
        favoriteUsers: [User],
        mode: Search.State.Mode
    ) -> Search.State.DisplayResult {
        switch mode {
        case .search:
            guard let users = users else {
                return .initial
            }
            if users.isEmpty {
                return .empty
            } else {
                return .success(.searchResult(
                    users.map { user in
                        UserRow.UserRowUIModel(
                            id: user.id,
                            login: user.login,
                            htmlUrl: user.htmlUrl,
                            avatarUrl: user.avatarUrl,
                            isFavorite: favoriteUsers.contains( where: { $0.id == user.id }),
                            didTapFavoriteButton: { id in
                                // TODO: Save favorite user after make component reducer
                            },
                            didTapRow: {
                                // TODO: Handle user row tap after make component reducer
                            }
                        )
                    })
                )
            }
        case .favorites:
            if favoriteUsers.isEmpty {
                return .empty
            } else {
                return .success(.favoites(
                    favoriteUsers.map { user in
                        UserRow.UserRowUIModel(
                            id: user.id,
                            login: user.login,
                            htmlUrl: user.htmlUrl,
                            avatarUrl: user.avatarUrl,
                            isFavorite: true,
                            didTapFavoriteButton: { id in
                                // TODO: Save favorite user after make component reducer
                            },
                            didTapRow: {
                                // TODO: Handle user row tap after make component reducer
                            }
                        )
                    }
                ))
            }
        }
    }
}

extension Search.State {
    enum DisplayResult: Equatable {
        case success(SuccessBodyType)
        case failure(String)
        case loading
        case empty
        case initial
        
        enum SuccessBodyType: Equatable {
            case searchResult([UserRow.UserRowUIModel])
            case favoites([UserRow.UserRowUIModel])
        }
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
                case .success(let successBodyType):
                    successBodyView(successBodyType)
                case .empty:
                    emptyView
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
    
    private func successBodyView(_ successBodyType: Search.State.DisplayResult.SuccessBodyType) -> some View {
        switch successBodyType {
        case .favoites(let favoriteUsers):
            List(favoriteUsers) { user in
                UserRow(userRowUIModel: user)
            }
            .listStyle(PlainListStyle())
        case .searchResult(let searchResults):
            List(searchResults) { user in
                UserRow(userRowUIModel: user)
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
