import Testing
import Foundation
import SwiftData
@testable import ArxivGraph

struct ArxivGraphTests {

    @Test
    func testCanvasPaperModelProperties() throws {
        // Create a sample ArxivPaper
        let sampleDate = Date(timeIntervalSince1970: 1640995200) // 2022-01-01 00:00:00 UTC
        let paper = ArxivGraph.ArxivPaper(
            id: "2201.00001",
            title: "Advancements in Quantum Computing",
            abstract: "This paper discusses recent advancements in quantum computing...",
            authors: ["Alice Quantum", "Bob Entanglement"],
            date: sampleDate,
            pdfUrl: URL(string: "https://arxiv.org/pdf/2201.00001.pdf")!
        )
        
        // Create a CanvasPaper instance
        let position = CGPoint(x: 100, y: 200)
        let canvasPaper = CanvasPaper(paper, position: position)
        
        // Test main properties of CanvasPaper
        #expect(canvasPaper.paper.id == "2201.00001")
        #expect(canvasPaper.paper.title == "Advancements in Quantum Computing")
        #expect(canvasPaper.paper.authors == ["Alice Quantum", "Bob Entanglement"])
        #expect(canvasPaper.paper.date == sampleDate)
        #expect(canvasPaper.paper.pdfUrl == URL(string: "https://arxiv.org/pdf/2201.00001.pdf")!)
        #expect(canvasPaper.position == position)
    }

    @Test
    func testCanvasPaperEncoding() throws {
        // Set up an in-memory SwiftData stack for testing
        let schema = Schema([CanvasPaper.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let modelContext = ModelContext(modelContainer)

        // Create a sample CanvasPaper
        let paper = ArxivGraph.ArxivPaper(
            id: "2201.00002",
            title: "SwiftData in Practice",
            abstract: "This paper explores the practical applications of SwiftData...",
            authors: ["Swift Developer"],
            date: Date(),
            pdfUrl: URL(string: "https://arxiv.org/pdf/2201.00002.pdf")!
        )
        let canvasPaper = CanvasPaper(paper, position: CGPoint(x: 150, y: 250))

        // Insert the CanvasPaper into the context
        modelContext.insert(canvasPaper)

        // Attempt to save the context
        do {
            try modelContext.save()
        } catch {
            Issue.record("Failed to save CanvasPaper: \(error)")
        }

        // Fetch the saved CanvasPaper
        let fetchDescriptor = FetchDescriptor<CanvasPaper>(predicate: #Predicate { $0.paper.id == "2201.00002" })
        let fetchedPapers = try modelContext.fetch(fetchDescriptor)

        // Verify the fetched CanvasPaper
        #expect(fetchedPapers.count == 1, "Should fetch exactly one CanvasPaper")
        if let fetchedPaper = fetchedPapers.first {
            #expect(fetchedPaper.paper.id == "2201.00002")
            #expect(fetchedPaper.paper.title == "SwiftData in Practice")
            #expect(fetchedPaper.paper.authors == ["Swift Developer"])
            #expect(fetchedPaper.position == CGPoint(x: 150, y: 250))
        }
    }
}
