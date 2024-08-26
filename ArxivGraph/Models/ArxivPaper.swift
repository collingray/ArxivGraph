import Foundation
import SwiftData

struct ArxivPaper: Codable, Identifiable {
    let id: String
    let title: String
    let abstract: String
    let authors: [String]
    let date: Date
    let pdfUrl: URL
    
    enum CodingKeys: String, CodingKey {
        case id, title, abstract, authors, date, pdfUrl
    }
}
