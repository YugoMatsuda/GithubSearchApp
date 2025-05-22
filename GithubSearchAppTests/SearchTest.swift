import ComposableArchitecture
import Testing
import Foundation

@MainActor
struct SearchTest {
    @Test
    func searchTextChanged_success() async {
        let response: [User] = (1...10).map { User.mock(id: $0) }
        let testScheduler = DispatchQueue.test
        let store = TestStoreOf<Search>(initialState: Search.State.init(
            displayResult: .initial)
        ) {
            Search()
        } withDependencies: {
            $0.networkService.searchUsers = { _ in
                response
            }
            $0.mainQueue = testScheduler.eraseToAnyScheduler()
        }
        
        await store.send(\.binding.searchText, "test") {
            $0.searchText = "test"
        }
        await testScheduler.advance(by: .seconds(0.5))
        
        await store.receive(\.internal.searchTextChangeDebounced) {
            $0.displayResult = .loading
        }
        
        await store.receive(\.internal.didReceiveSearchResult.success) {
            $0.displayResult = .success(
                SearchBody.State.init(
                    mode: $0.mode,
                    searchList: SearchList.State.init(
                        items: .init(
                            uniqueElements: response.map { user in
                                UserRow.State.init(
                                    user: user,
                                    isFavorite: false
                                )
                            }
                        )
                    ),
                    favoriteList: FavoriteList.State(items: [])
                )
            )
        }
    }
    
    @Test
    func searchTextChanged_failure() async {
        let testScheduler = DispatchQueue.test
        let store = TestStoreOf<Search>(initialState: Search.State.init(
            displayResult: .initial)
        ) {
            Search()
        } withDependencies: {
            $0.networkService.searchUsers = { _ in
                throw SearchTestError()
            }
            $0.mainQueue = testScheduler.eraseToAnyScheduler()
        }
        
        await store.send(\.binding.searchText, "test") {
            $0.searchText = "test"
        }
        await testScheduler.advance(by: .seconds(0.5))
        
        await store.receive(\.internal.searchTextChangeDebounced) {
            $0.displayResult = .loading
        }
        
        await store.receive(\.internal.didReceiveSearchResult.failure) {
            $0.displayResult = .failure("Error: Test error")
        }
    }
    
    @Test
    func didTapSeachClearButton() async {
        let response: [User] = (1...10).map { User.mock(id: $0) }
        let testScheduler = DispatchQueue.test
        let store = TestStoreOf<Search>(initialState: Search.State.init(
            displayResult: .initial)
        ) {
            Search()
        } withDependencies: {
            $0.networkService.searchUsers = { _ in
                response
            }
            $0.mainQueue = testScheduler.eraseToAnyScheduler()
        }
        
        await store.send(\.binding.searchText, "test") {
            $0.searchText = "test"
        }
        await testScheduler.advance(by: .seconds(0.5))
        
        await store.receive(\.internal.searchTextChangeDebounced) {
            $0.displayResult = .loading
        }
        
        await store.receive(\.internal.didReceiveSearchResult.success) {
            $0.displayResult = .success(
                SearchBody.State.init(
                    mode: $0.mode,
                    searchList: SearchList.State.init(
                        items: .init(
                            uniqueElements: response.map { user in
                                UserRow.State.init(
                                    user: user,
                                    isFavorite: false
                                )
                            }
                        )
                    ),
                    favoriteList: FavoriteList.State(items: [])
                )
            )
        }
        
        await store.send(\.view.didTapSeachClearButton) {
            $0.searchText = ""
            $0.displayResult = .initial
        }
    }
    
    @Test
    func changeMode() async throws {
        let response: [User] = (1...10).map { User.mock(id: $0) }
        let favorites: [User] = (1...5).map { User.mock(id: $0) }
        let store = TestStoreOf<Search>(initialState: Search.State.init(
            displayResult: .success(
                SearchBody.State.init(
                    mode: .search,
                    searchList: SearchList.State.init(
                        items: .init(
                            uniqueElements: response.map { user in
                                UserRow.State.init(
                                    user: user,
                                    isFavorite: favorites.contains( where: { $0.id == user.id })
                                )
                            }
                        )
                    ),
                    favoriteList: FavoriteList.State.init(
                        items: .init(
                            uniqueElements: favorites.map { user in
                                UserRow.State.init(
                                    user: user,
                                    isFavorite: true
                                )
                            }
                        )
                    )
                )
            ))
        ) {
            Search()
        } withDependencies: {
            $0.userDefaultsService.getFavoriteUsers = { favorites }
            $0.networkService.searchUsers = { _ in
                response
            }
        }
        
        await store.send(\.binding.mode, .favorites) {
            $0.mode = .favorites
            $0.displayResult = .success(
                SearchBody.State.init(
                    mode: .favorites,
                    searchList: SearchList.State.init(
                        items: .init(
                            uniqueElements: response.map { user in
                                UserRow.State.init(
                                    user: user,
                                    isFavorite: favorites.contains( where: { $0.id == user.id })
                                )
                            }
                        )
                    ),
                    favoriteList: FavoriteList.State.init(
                        items: .init(
                            uniqueElements: favorites.map { user in
                                UserRow.State.init(
                                    user: user,
                                    isFavorite: true
                                )
                            }
                        )
                    )
                )
            )
        }
    }
    
    
    @Test
    func navigation() async throws {
        let response: [User] = (1...10).map { User.mock(id: $0) }
        let store = TestStoreOf<Search>(initialState: Search.State.init(
            displayResult: .success(
                SearchBody.State.init(
                    mode: .favorites,
                    searchList: SearchList.State.init(
                        items: .init(
                            uniqueElements: response.map { user in
                                UserRow.State.init(
                                    user: user,
                                    isFavorite: false
                                )
                            }
                        )
                    ),
                    favoriteList: FavoriteList.State.init(
                        items: .init(
                            uniqueElements: []
                        )
                    )
                )
            ))
        ) {
            Search()
        }
        await store.send(.searchBody(.delegate(.didTapListRow(user: User.mock(id: 1))))) { $0.path = [User.mock(id: 1)]
        }
    }
}
    

extension SearchTest {
    struct SearchTestError: LocalizedError, Equatable {
        var errorDescription: String? {
            return "Test error"
        }
    }
}
