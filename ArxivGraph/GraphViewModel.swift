import SwiftUI
import Foundation
import Combine

class GraphViewModel: ObservableObject {
    @Published var papers: [ArxivPaper] = []
    @Published var paperPositions: [String: CGPoint] = [:]
    @Published var searchText: String = ""
    private var cancellables: Set<AnyCancellable> = []
    
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
                self?.paperPositions[paper.id] = CGPoint(x: 0, y: 200)
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
    
    func updatePosition(for paperId: String, to newPosition: CGPoint) {
        paperPositions[paperId] = newPosition
    }
    
    func updatePosition(for paperId: String, by offset: CGSize) {
        paperPositions[paperId] = (paperPositions[paperId] ?? .zero).applying(.init(translationX: offset.width, y: offset.height))
    }
}
