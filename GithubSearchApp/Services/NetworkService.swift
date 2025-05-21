import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError
    case noData
    case rateLimitExceeded
}

class NetworkService {
    func searchUsers(query: String) async throws -> [User] {
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
    }
    
    func getUserDetails(username: String) async throws -> UserDetail {
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
    }
    
    // New method to fetch user repositories
    func getUserRepositories(username: String) async throws -> [Repository] {
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
}
