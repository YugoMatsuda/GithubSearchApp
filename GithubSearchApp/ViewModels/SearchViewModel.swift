import Foundation
import Combine

class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var users: [User] = []

    @Published var userRowUIModels: [UserRow.UserRowUIModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasSearched = false
    @Published private(set) var favoriteUsers: [User] = []
    @Published var path: [User] = []
    @Published var mode: Mode = .search
    
    private let networkService = NetworkService()
    private let userDefaultsService = UserDefaultsService()
    private var cancellables = Set<AnyCancellable>()
    
    var facfavoriteUserRowUIModel: [UserRow.UserRowUIModel]  {
        favoriteUsers.map { user in
            UserRow.UserRowUIModel(
                id: user.id,
                login: user.login,
                htmlUrl: user.htmlUrl,
                avatarUrl: user.avatarUrl,
                isFavorite: true,
                didTapFavoriteButton: { [weak self] id in
                    self?.saveFavoriteUser(userId: id)
                },
                didTapRow: { [weak self] in
                    self?.didTapUserRow(user)
                }
            )
        }
    }
    
    init() {
        $searchText
            .removeDuplicates()
            .filter { !$0.isEmpty }
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] query in
                self?.searchUsers(query: query)
            }
            .store(in: &cancellables)
        
        favoriteUsers = userDefaultsService.getFavoriteUsers()
        
        Publishers.CombineLatest($users, $favoriteUsers)
            .map { users, favoriteUsers in
                users.map { user in
                    UserRow.UserRowUIModel(
                        id: user.id,
                        login: user.login,
                        htmlUrl: user.htmlUrl,
                        avatarUrl: user.avatarUrl,
                        isFavorite: favoriteUsers.contains( where: { $0.id == user.id }),
                        didTapFavoriteButton: { [weak self] id in
                            self?.saveFavoriteUser(userId: id)
                        },
                        didTapRow: { [weak self] in
                            self?.didTapUserRow(user)
                        }
                    )
                }
            }
            .assign(to: &$userRowUIModels)
    }
    
    func searchUsers(query: String) {
        guard !query.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        hasSearched = true
        
        Task {
            do {
                let users = try await networkService.searchUsers(query: query)
                
                await MainActor.run {
                    self.users = users
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.users = []
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func saveFavoriteUser(userId: Int) {
        if favoriteUsers.contains(where: { $0.id == userId }) {
            favoriteUsers.removeAll { $0.id == userId }
        } else {
            guard let user = users.first(where: { $0.id == userId }) else { return }
            favoriteUsers.append(user)
        }
        userDefaultsService.saveFavoriteUser(favoriteUsers)
    }
    
    func didTapUserRow(_ user: User) {
        path.append(user)
    }
}

extension SearchViewModel {
    enum Mode: String, Identifiable, CaseIterable {
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
