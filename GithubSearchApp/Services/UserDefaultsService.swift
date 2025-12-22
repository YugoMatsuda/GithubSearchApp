//
//  UserDefaultsService.swift
//  GithubSearchApp
//
//  Created by Yugo Matsuda on 2025-05-21.
//

import Foundation

class UserDefaultsService {
    let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }
    
    func saveFavoriteUser(_ users: [User]) {
        guard let data = try? JSONEncoder().encode(users) else {
            print("Failed to encode users")
            return
        }
        userDefaults.set(data, forKey: UserDefaultsKey.favoriteUsers.rawValue)
    }
    
    func getFavoriteUsers() -> [User] {
        guard let data = userDefaults.data(forKey: UserDefaultsKey.favoriteUsers.rawValue) else {
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
}

extension UserDefaultsService {
    enum UserDefaultsKey: String {
        case favoriteUsers
    }
}
