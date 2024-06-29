import SwiftUI
import Foundation
import Combine

class GraphViewModel: ObservableObject {
    @Published var papers: [ArxivPaper] = []
    @Published var images: [NSImage] = []
    @Published var objectPositions: [String: CGPoint] = [:]
    @Published var canvasPosition: CGPoint = .zero
    
    @Published var searchText: String = ""
    
    private var cancellables: Set<AnyCancellable> = []
    
    var draggingCanvas: Bool = false
    var draggingObjectId: String? = nil
    
    @Published var dragOffset: CGPoint = .zero
    
    init() {
        
    }
    
    init(papers: [ArxivPaper]) {
        self.papers = papers
        self.objectPositions = papers.reduce(into: [:]) { result, paper in
            result[paper.id] = CGPoint(x: 0, y: 0)
        }
    }
    
    func addPaper(identifier: String) {
        ArxivAPIClient.shared.fetchPaper(identifier: identifier)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Error fetching paper: \(error)")
                }
            } receiveValue: { [weak self] paper in
                self?.objectPositions[paper.id] = -(self?.canvasPosition ?? .zero)
                self?.papers.append(paper)
                self?.addPaperCitations(for: paper)
            }
            .store(in: &cancellables)
    }
    
    func removePaper(identifier: String) {
        if let i = papers.firstIndex(where: { $0.id == identifier }) {
            papers.remove(at: i)
            objectPositions.removeValue(forKey: identifier)
        }
    }
    
    func containsPaper(identifier: String) -> Bool {
        return papers.contains { $0.id == identifier }
    }
    
    private func addPaperCitations(for paper: ArxivPaper) {
        ArxivAPIClient.shared.fetchCitations(for: paper)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Error fetching citations: \(error)")
                }
            } receiveValue: { [weak self] citations in
                print("Got citations: \(citations)")
                if let paperId = self?.papers.firstIndex(where: { $0.id == paper.id }) {
                    self?.papers[paperId].citations = citations
                }
            }
            .store(in: &cancellables)
    }
    
    func loadImage(from providers: [NSItemProvider], at: CGPoint) -> Bool {
        if let item = providers.first {
            item.loadObject(ofClass: NSImage.self) { image, error in
                if let image = image as? NSImage {
                    DispatchQueue.main.async {
                        self.images.append(image)
                        self.objectPositions[String(image.hashValue)] = at
                    }
                }
            }
            return true
        }
        return false
    }
    
    func positionOf(id: String) -> CGPoint {
        let position = (objectPositions[id] ?? .zero) + canvasPosition
        
        if draggingCanvas || draggingObjectId == id {
            return position + dragOffset
        } else {
            return position
        }
    }
    
    func centerOn(id: String) {
        canvasPosition = -(objectPositions[id] ?? .zero)
    }
    
    func draggingCanvas(by offset: CGSize) {
        dragOffset = CGPoint(x: offset.width, y: offset.height)
        draggingCanvas = true
    }
    
    func canvasDraggingEnded() {
        canvasPosition = canvasPosition + dragOffset
        dragOffset = .zero
        draggingCanvas = false
    }
    
    func draggingObject(_ id: String, by offset: CGSize) {
        dragOffset = CGPoint(x: offset.width, y: offset.height)
        draggingObjectId = id
    }
    
    func objectDraggingEnded(_ id: String) {
        objectPositions[id] = (objectPositions[id] ?? .zero) + dragOffset
        dragOffset = .zero
        draggingObjectId = nil
    }
}

extension CGPoint {
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
    
    static prefix func -(point: CGPoint) -> CGPoint {
        return CGPoint(x: -point.x, y: -point.y)
    }
}
