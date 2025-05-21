import Foundation
import Combine

class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var path: [User] = []
    @Published var mode: Mode = .search
    @Published var displayResult: DisplayResult = .initial
    private var userCurrentValueSubject = CurrentValueSubject<[User], Never>([])
    private var favoriteUsersCurrentValueSubject = CurrentValueSubject<[User], Never>([])
    private let networkService = NetworkService()
    private let userDefaultsService = UserDefaultsService.liveValue
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $searchText
            .removeDuplicates()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] query in
                guard !query.isEmpty else {
                    self?.userCurrentValueSubject.value = []
                    self?.displayResult = .initial
                    return
                }
                self?.searchUsers(query: query)
            }
            .store(in: &cancellables)
        
        favoriteUsersCurrentValueSubject.value = userDefaultsService.getFavoriteUsers()

        Publishers.CombineLatest3(
            userCurrentValueSubject.eraseToAnyPublisher(),
            favoriteUsersCurrentValueSubject.eraseToAnyPublisher(),
            $mode.removeDuplicates()
        )
        .map { users, favoriteUsers, mode -> DisplayResult in
            switch mode {
            case .search:
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
                                didTapFavoriteButton: { [weak self] id in
                                    self?.saveFavoriteUser(userId: id)
                                },
                                didTapRow: { [weak self] in
                                    self?.didTapUserRow(user)
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
                                didTapFavoriteButton: { [weak self] id in
                                    self?.saveFavoriteUser(userId: id)
                                },
                                didTapRow: { [weak self] in
                                    self?.didTapUserRow(user)
                                }
                            )
                        }
                    ))
                }
            }
        }
        .assign(to: &$displayResult)
    }
    
    private func searchUsers(query: String) {
        displayResult = .loading
        Task {
            do {
                let users = try await networkService.searchUsers(query: query)
                
                await MainActor.run {
                    self.userCurrentValueSubject.value = users
                }
            } catch {
                await MainActor.run {
                    displayResult = .failure("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func saveFavoriteUser(userId: Int) {
        if favoriteUsersCurrentValueSubject.value.contains(where: { $0.id == userId }) {
            favoriteUsersCurrentValueSubject.value.removeAll { $0.id == userId }
        } else {
            guard let user = userCurrentValueSubject.value.first(where: { $0.id == userId }) else { return }
            favoriteUsersCurrentValueSubject.value.append(user)
        }
        userDefaultsService.saveFavoriteUser(favoriteUsersCurrentValueSubject.value)
    }
    
    private func didTapUserRow(_ user: User) {
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
}
