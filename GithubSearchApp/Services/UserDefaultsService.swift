import Foundation
import ComposableArchitecture

struct UserDefaultsService: Sendable {
    var saveFavoriteUser: @Sendable ([User]) -> Void
    var getFavoriteUsers: @Sendable () -> [User]
}

extension DependencyValues {
    var userDefaultsService: UserDefaultsService {
        get { self[UserDefaultsService.self] }
        set { self[UserDefaultsService.self] = newValue }
    }
}

extension UserDefaultsService: DependencyKey {
    static let liveValue = Self(
        saveFavoriteUser: { users in
            guard let data = try? JSONEncoder().encode(users) else {
                print("Failed to encode users")
                return
            }
            UserDefaults.standard.set(data, forKey: UserDefaultsKey.favoriteUsers.rawValue)
        },
        getFavoriteUsers: {
            guard let data = UserDefaults.standard.data(forKey: UserDefaultsKey.favoriteUsers.rawValue) else {
                return []
            }
            do {
                let users = try JSONDecoder().decode([User].self, from: data)
                return users
            } catch {
                print("Failed to decode user IDs: \(error)")
                return []
            }
        }
    )
}

extension UserDefaultsService {
    enum UserDefaultsKey: String {
        case favoriteUsers
    }
}

extension UserDefaultsService: TestDependencyKey {
    static let testValue: UserDefaultsService = Self(
        saveFavoriteUser: { _ in },
        getFavoriteUsers: { [] }
    )
}
