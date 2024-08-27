import Foundation
import Combine

class SemanticScholarAPIClient {
    static let shared = SemanticScholarAPIClient()
    private let baseURL = "https://api.semanticscholar.org/graph/v1"
    private let apiKey: String

    init(apiKey: String = "") {
        self.apiKey = apiKey
    }

    private func createRequest(path: String, queryItems: [URLQueryItem] = []) -> URLRequest? {
        var components = URLComponents(string: baseURL + path)
        components?.queryItems = queryItems

        guard let url = components?.url else { return nil }

        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        if !apiKey.isEmpty {
            request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        }

        return request
    }

    private func fetch<T: Decodable>(_ request: URLRequest) -> AnyPublisher<T, Error> {
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    print(String(decoding: data, as: Unicode.UTF8.self))
                    throw URLError(.badServerResponse)
                }
                print(String(decoding: data, as: Unicode.UTF8.self))
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }

    func fetchPaper(paperId: String) -> AnyPublisher<Paper, Error> {
        guard let request = createRequest(path: "/paper/\(paperId)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return fetch(request)
    }

    func fetchCitations(paperId: String, limit: Int = 100, offset: Int = 0) -> AnyPublisher<BatchedResponse<Citation>, Error> {
        guard let request = createRequest(path: "/paper/\(paperId)/citations",
                                          queryItems: [URLQueryItem(name: "limit", value: "\(limit)"),
                                                       URLQueryItem(name: "offset", value: "\(offset)")]) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return fetch(request)
    }

    func fetchAuthorPapers(authorId: String, limit: Int = 100, offset: Int = 0) -> AnyPublisher<BatchedResponse<Paper>, Error> {
        guard let request = createRequest(path: "/author/\(authorId)/papers",
                                          queryItems: [URLQueryItem(name: "limit", value: "\(limit)"),
                                                       URLQueryItem(name: "offset", value: "\(offset)")]) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return fetch(request)
    }

    func fetchRecommendations(paperId: String) -> AnyPublisher<RecommendationsResponse, Error> {
        guard let request = createRequest(path: "/paper/\(paperId)/recommendations") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return fetch(request)
    }

    // Async/await versions of the above functions

    func fetchPaper(paperId: String) async throws -> Paper {
        let response = try await fetchPaper(paperId: paperId).values.first { (_: Paper) in true }!
        return response
    }

    func fetchCitations(paperId: String, limit: Int = 100, offset: Int = 0) async throws -> BatchedResponse<Citation> {
        try await fetchCitations(paperId: paperId, limit: limit, offset: offset).values.first { (_: BatchedResponse<Citation>) in true }!
    }

    func fetchAuthorPapers(authorId: String, limit: Int = 100, offset: Int = 0) async throws -> BatchedResponse<Paper> {
        try await fetchAuthorPapers(authorId: authorId, limit: limit, offset: offset).values.first { (_: BatchedResponse<Paper>) in true }!
    }

    func fetchRecommendations(paperId: String) async throws -> RecommendationsResponse {
        try await fetchRecommendations(paperId: paperId).values.first { (_: RecommendationsResponse) in true }!
    }
}

// MARK: - Data Models

struct Paper: Codable {
    let paperId: String
    let externalIds: ExternalIDs
}

struct ExternalIDs: Codable {
    let ArXiv: String?
}

struct Author: Codable {
    let authorId: String
    let name: String
}

struct BatchedResponse<T: Codable>: Codable {
    let data: [T]
    let offset: Int
    let next: Int?
}

struct Citation: Codable {
    let citingPaper: Paper
}

struct RecommendationsResponse: Codable {
    let data: [Paper]
}
