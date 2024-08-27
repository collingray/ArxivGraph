import Testing
import Combine
@testable import ArxivGraph

struct SemanticScholarAPIClientTests {
    var client: SemanticScholarAPIClient = .shared
    var cancellables: Set<AnyCancellable> = []
    
    @Test("Fetch paper")
    func testFetchPaper() async throws {
        let paperId = "649def34f8be52c8b66281af98ae884c09aef38b"
        
        let paper = try await client.fetchPaper(paperId: paperId)
        
        #expect(paper.paperId == paperId)
    }
    
    @Test("Fetch citations")
    func testFetchCitations() async throws {
        let paperId = "649def34f8be52c8b66281af98ae884c09aef38b"
        
        let response = try await client.fetchCitations(paperId: paperId, limit: 10)
        
        #expect(!response.data.isEmpty)
        #expect(response.data.count <= 10)
        #expect(response.offset == 0)
    }
    
    @Test("Fetch author papers")
    func testFetchAuthorPapers() async throws {
        let authorId = "1741101"
        
        let response = try await client.fetchAuthorPapers(authorId: authorId, limit: 5)
        
        #expect(!response.data.isEmpty)
        #expect(response.data.count <= 5)
        #expect(response.offset == 0)
    }
    
    @Test("Fetch recommendations")
    func testFetchRecommendations() async throws {
        let paperId = "649def34f8be52c8b66281af98ae884c09aef38b"
        
        let response = try await client.fetchRecommendations(paperId: paperId)
        
        #expect(!response.data.isEmpty)
    }
}
