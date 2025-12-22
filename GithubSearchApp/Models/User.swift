import Foundation

struct UserSearchResponse: Codable {
    let totalCount: Int
    let items: [User]
    
    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case items
    }
}

struct User: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let login: String
    let avatarUrl: String
    let htmlUrl: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case login
        case avatarUrl = "avatar_url"
        case htmlUrl = "html_url"
    }
}

extension User {
    static func mock(
        id: Int = 0,
        login: String = "login",
        avatarUrl: String = "avatarUrl",
        htmlUrl: String = "htmlUrl"
    ) -> User {
        User(
            id: id,
            login: login,
            avatarUrl: avatarUrl,
            htmlUrl: htmlUrl
        )
    }
}

struct UserDetail: Codable, Equatable {
    let id: Int
    let login: String
    let avatarUrl: String
    let name: String?
    let bio: String?
    let publicRepos: Int
    let followers: Int
    let following: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case login
        case avatarUrl = "avatar_url"
        case name
        case bio
        case publicRepos = "public_repos"
        case followers
        case following
    }
}

extension UserDetail {
    static func mock(
        id: Int = 0,
        login: String = "login",
        avatarUrl: String = "avatarUrl",
        name: String? = "name",
        bio: String? = "bio",
        publicRepos: Int = 0,
        followers: Int = 0,
        following: Int = 0
    ) -> UserDetail {
        UserDetail(
            id: id,
            login: login,
            avatarUrl: avatarUrl,
            name: name,
            bio: bio,
            publicRepos: publicRepos,
            followers: followers,
            following: following
        )
    }
}
