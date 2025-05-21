import Foundation

struct Repository: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let description: String?
    let stargazersCount: Int
    let language: String?
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case stargazersCount = "stargazers_count"
        case language
        case updatedAt = "updated_at"
    }
}
