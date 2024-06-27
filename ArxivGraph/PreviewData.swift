import Foundation

struct PreviewData {
    static let paper1 = ArxivPaper(id: "1", title: "Title 1", abstract: "Abstract 1", authors: ["Author 1", "Author 2", "Author 3"], date: Date(), pdfUrl: URL(filePath: "https://arxiv.org/abs/1")!, citations: [])
    static let paper2 = ArxivPaper(id: "2", title: "Title 2", abstract: "Abstract 2", authors: ["Author 1", "Author 2", "Author 3"], date: Date(), pdfUrl: URL(filePath: "https://arxiv.org/abs/2")!, citations: [paper1])
    static let paper3 = ArxivPaper(id: "3", title: "Title 3", abstract: "Abstract 3", authors: ["Author 1", "Author 2", "Author 3"], date: Date(), pdfUrl: URL(filePath: "https://arxiv.org/abs/3")!, citations: [])
    static let paper4 = ArxivPaper(id: "4", title: "Title 4", abstract: "Abstract 4", authors: ["Author 1", "Author 2", "Author 3"], date: Date(), pdfUrl: URL(filePath: "https://arxiv.org/abs/4")!, citations: [paper2, paper3])
    
    static let graphViewModel = GraphViewModel(papers: [
        paper1,
        paper2,
        paper3,
        paper4,
    ])
}
