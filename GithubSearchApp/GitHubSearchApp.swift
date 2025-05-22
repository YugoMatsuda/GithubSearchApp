import SwiftUI
import ComposableArchitecture

@main
struct GitHubSearchApp: App {
    var body: some Scene {
        WindowGroup {
            SearchView(store: Store(
                initialState: Search.State.init(
                    displayResult: .initial,
                    favoriteUsers: UserDefaultsService.liveValue.getFavoriteUsers()),
                reducer: { Search() })
            )
        }
    }
}
