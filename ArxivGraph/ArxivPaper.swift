import Foundation

struct ArxivPaper: Identifiable {
    let id: String
    let title: String
    let abstract: String
    let authors: [String]
    let date: Date
    let pdfUrl: URL
    var citations: [ArxivPaper]
}
