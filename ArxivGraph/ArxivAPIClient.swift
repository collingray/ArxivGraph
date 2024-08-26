import SwiftUI
import Combine
import PDFKit
import Foundation
import XMLCoder

class ArxivAPIClient {
    static let shared = ArxivAPIClient()
    private let baseURL = "http://export.arxiv.org/api/query"
    
    func fetchPapersPub(identifiers: [String]) -> AnyPublisher<[ArxivPaper], Error> {
        let urlString = "\(baseURL)?id_list=\(identifiers.joined(separator: ","))"

        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: ArxivResponse.self, decoder: XMLDecoder())
            .tryMap { response -> [ArxivPaper] in
                return response.entry.map { entry in
                    ArxivPaper(
                        id: String(entry.id.dropFirst(21)), // drops http://arxiv.org/abs/
                        title: entry.title.replacingOccurrences(of: "\n", with: ""),
                        abstract: entry.summary,
                        authors: entry.authors,
                        date: ISO8601DateFormatter().date(from: entry.published) ?? Date(),
                        pdfUrl: URL(string: entry.pdfLink)!
                    )
                }
            }
            .eraseToAnyPublisher()
    }
    
    func fetchPapers(identifiers: [String]) async throws -> [ArxivPaper] {
        let papers = try await fetchPapersPub(identifiers: identifiers).values.first { (_: [ArxivPaper]) in
            true
        }
        
        if let papers = papers {
            return papers
        } else {
            throw URLError(.cannotParseResponse)
        }
    }
    
    func fetchPaperPub(identifier: String) -> AnyPublisher<ArxivPaper, Error> {
        return fetchPapersPub(identifiers: [identifier])
            .tryMap { entries in
                guard let entry = entries.first else {
                    throw URLError(.cannotParseResponse)
                }
                
                return entry
            }
            .eraseToAnyPublisher()
    }
    
    func fetchPaper(identifier: String) async throws -> ArxivPaper {
        let paper = try await fetchPaperPub(identifier: identifier)
            .values
            .first { (_: ArxivPaper) in
                true
            }
        
        if let paper = paper {
            print("got paper: \(paper.id)")
            return paper
        } else {
            throw URLError(.cannotParseResponse)
        }
    }
    
    func fetchCitationsPub(for paper: ArxivPaper) -> AnyPublisher<[ArxivPaper], Error> {
        return Future<[String]?, Error>() { promise in
            PDFUtils.fetchPaperCitations(paper) { citations in
                promise(Result.success(citations))
            }
        }.tryMap { citations in
            guard let citations = citations else {
                throw URLError(.cannotParseResponse)
            }
                        
            return citations
        }.flatMap { citations in
            return self.fetchPapersPub(identifiers: citations)
        }.eraseToAnyPublisher()
    }
    
    func fetchCitations(for paper: ArxivPaper) async throws -> [ArxivPaper] {
        let citations = try await fetchCitationsPub(for: paper)
            .values
            .first { (_: [ArxivPaper]) in
                true
            }
        
        if let citations = citations {
            return citations.filter({$0.id != paper.id})
        } else {
            throw URLError(.cannotParseResponse)
        }
    }
}

struct ArxivResponse: Decodable {
    let entry: [ArxivEntry]
}

struct ArxivEntry: Decodable {
    let id: String
    let title: String
    let summary: String
    let authors: [String]
    let published: String
    let pdfLink: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, summary, author, published, link
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        summary = try container.decode(String.self, forKey: .summary)
        authors = try container.decode([Author].self, forKey: .author).map({ $0.name })
        published = try container.decode(String.self, forKey: .published)
        
        // Custom decoding for pdfLink
        let links = try container.decode([Link].self, forKey: .link)
        if let pdfLink = links.first(where: { $0.title == "pdf" })?.href {
            self.pdfLink = pdfLink
        } else {
            throw DecodingError.dataCorruptedError(forKey: .link, in: container, debugDescription: "PDF link not found")
        }
    }
    
    private struct Author: Codable {
        let name: String
        
        enum CodingKeys: String, CodingKey {
            case name
        }
    }
    
    // Helper struct to decode individual link elements
    private struct Link: Codable {
        let href: String
        let title: String?
        
        enum CodingKeys: String, CodingKey {
            case href
            case title
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            href = try container.decode(String.self, forKey: .href)
            title = try container.decodeIfPresent(String.self, forKey: .title)
        }
    }
}
