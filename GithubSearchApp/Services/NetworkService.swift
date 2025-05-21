import Foundation
import ComposableArchitecture


enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError
    case noData
    case rateLimitExceeded
}

struct NetworkService: Sendable {
    var searchUsers: @Sendable (String) async throws  -> [User]
    var getUserDetails: @Sendable (String) async throws -> UserDetail
    var getUserRepositories: @Sendable (String) async throws -> [Repository]
}

extension DependencyValues {
    var networkService: NetworkService {
        get { self[NetworkService.self] }
        set { self[NetworkService.self] = newValue }
    }
}

extension NetworkService: DependencyKey {
    static let liveValue = Self(
        searchUsers: { query in
            guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: "https://api.github.com/search/users?q=\(encodedQuery)") else {
                throw NetworkError.invalidURL
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 403 {
                    throw NetworkError.rateLimitExceeded
                }
                throw NetworkError.httpError(httpResponse.statusCode)
            }
            
            do {
                let searchResponse = try JSONDecoder().decode(UserSearchResponse.self, from: data)
                return searchResponse.items
            } catch {
                print("Decoding error: \(error)")
                throw NetworkError.decodingError
            }
        },
        getUserDetails: { username in
            guard let url = URL(string: "https://api.github.com/users/\(username)") else {
                throw NetworkError.invalidURL
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 403 {
                    throw NetworkError.rateLimitExceeded
                }
                throw NetworkError.httpError(httpResponse.statusCode)
            }
            
            do {
                return try JSONDecoder().decode(UserDetail.self, from: data)
            } catch {
                print("Decoding error: \(error)")
                throw NetworkError.decodingError
            }
        },
        getUserRepositories: { username in
            guard let url = URL(string: "https://api.github.com/users/\(username)/repos?sort=updated") else {
                throw NetworkError.invalidURL
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.httpError(httpResponse.statusCode)
            }
            
            do {
                return try JSONDecoder().decode([Repository].self, from: data)
            } catch {
                print("Decoding error: \(error)")
                throw NetworkError.decodingError
            }
        }
    )
}
