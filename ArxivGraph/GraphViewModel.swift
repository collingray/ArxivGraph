import SwiftUI
import Foundation
import Combine

class GraphViewModel: ObservableObject {
    @Published var papers: [ArxivPaper] = []
    @Published var paperPositions: [String: CGPoint] = [:]
    @Published var canvasPosition: CGPoint = .zero
    
    @Published var searchText: String = ""
    
    private var cancellables: Set<AnyCancellable> = []
    
    var draggingCanvas: Bool = false
    var draggingPaperId: String? = nil
    
    @Published var dragOffset: CGPoint = .zero
    
    init() {
        
    }
    
    init(papers: [ArxivPaper]) {
        self.papers = papers
        self.paperPositions = papers.reduce(into: [:]) { result, paper in
            result[paper.id] = CGPoint(x: 0, y: 100)
        }
    }
    
    func addPaper(identifier: String) {
        ArxivAPIClient.shared.fetchPaper(identifier: identifier)
            .receive(on: DispatchQueue.main)
            .flatMap { paper in
                return ArxivAPIClient.shared.fetchCitations(for: paper)
                    .receive(on: DispatchQueue.main)
                    .map { citations in
                        var newPaper = paper
                        newPaper.citations = citations
                        return newPaper
                    }
            }
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Error fetching paper: \(error)")
                }
            } receiveValue: { [weak self] paper in
                self?.papers.append(paper)
                self?.paperPositions[paper.id] = -(self?.canvasPosition ?? .zero)
            }
            .store(in: &cancellables)
    }
    
    func removePaper(identifier: String) {
        if let i = papers.firstIndex(where: { $0.id == identifier }) {
            papers.remove(at: i)
            paperPositions.removeValue(forKey: identifier)
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
    
    func positionOf(id: String) -> CGPoint {
        let position = (paperPositions[id] ?? .zero) + canvasPosition
        
        if draggingCanvas || draggingPaperId == id {
            return position + dragOffset
        } else {
            return position
        }
    }
    
    func centerOn(id: String) {
        canvasPosition = -(paperPositions[id] ?? .zero)
    }
    
    func canvasDragging(by offset: CGSize) {
        dragOffset = CGPoint(x: offset.width, y: offset.height)
        draggingCanvas = true
    }
    
    func canvasDraggingEnded() {
        canvasPosition = canvasPosition + dragOffset
        dragOffset = .zero
        draggingCanvas = false
    }
    
    func paperDragging(_ paperId: String, by offset: CGSize) {
        dragOffset = CGPoint(x: offset.width, y: offset.height)
        draggingPaperId = paperId
    }
    
    func paperDraggingEnded(_ paperId: String) {
        paperPositions[paperId] = (paperPositions[paperId] ?? .zero) + dragOffset
        dragOffset = .zero
        draggingPaperId = nil
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
