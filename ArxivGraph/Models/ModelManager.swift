import SwiftUI
import SwiftData
import Combine

@MainActor
class ModelManager {
    private let modelContext: ModelContext
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Paper Operations
    
    func fetchPapers() -> [CanvasPaper] {
        let descriptor = FetchDescriptor<CanvasPaper>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func addPaper(identifier: String, position: CGPoint) async throws {        
        let paper = try await ArxivAPIClient.shared.fetchPaper(identifier: identifier)
        let canvasPaper = CanvasPaper(paper, position: position)
        self.modelContext.insert(canvasPaper)
        canvasPaper.citations = try await ArxivAPIClient.shared.fetchCitations(for: paper)
    }
    
    func removePaper(id: String) {
        if let paper = fetchPapers().first(where: { $0.id == id }) {
            modelContext.delete(paper)
        }
    }
    
    func movePaper(id: String, newPosition: CGPoint) {
        if let paper = fetchPapers().first(where: { $0.id == id }) {
            paper.position = newPosition
        }
    }
    
    // MARK: - Image Operations
    
    func fetchImages() -> [CanvasImage] {
        let descriptor = FetchDescriptor<CanvasImage>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func addImage(_ image: CanvasImage) {
        modelContext.insert(image)
    }
    
    func removeImage(id: String) {
        if let image = fetchImages().first(where: { $0.id == id }) {
            modelContext.delete(image)
        }
    }
    
    func moveImage(id: String, newPosition: CGPoint) {
        if let image = fetchImages().first(where: { $0.id == id }) {
            image.position = newPosition
        }
    }
}
