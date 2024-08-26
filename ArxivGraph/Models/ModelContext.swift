import SwiftUI
import SwiftData

extension ModelContext {
    @MainActor
    func addPaper(identifier: String, position: CGPoint) async throws {
        let paper = try await ArxivAPIClient.shared.fetchPaper(identifier: identifier)
        let canvasPaper = CanvasPaper(paper, position: position)
        self.insert(canvasPaper)
        canvasPaper.citations = try await ArxivAPIClient.shared.fetchCitations(for: paper)
    }
}
