import Foundation
import PDFKit

struct PDFUtils {
    static var documentDir: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    static func fetchPaper(_ paper: ArxivPaper, completion: @escaping (URL?) -> Void) {
        if let dir = documentDir {
            let localUrl = dir.appendingPathComponent(paper.title + ".pdf")
            
            print("File path: \(localUrl.path(percentEncoded: false))")

            if !FileManager.default.fileExists(atPath: localUrl.path(percentEncoded: false)) {
                print("File does not exist - fetching")
                
                let task = URLSession.shared.downloadTask(with: paper.pdfUrl) { tempUrl, response, error in
                    if let tempUrl = tempUrl, error == nil {
                        do {
                            try FileManager.default.moveItem(at: tempUrl, to: localUrl)
                            print("PDF saved to: \(localUrl)")
                            completion(localUrl)
                        } catch {
                            completion(nil)
                            print("Error saving PDF: \(error)")
                        }
                    } else if let error = error {
                        completion(nil)
                        print("Error downloading PDF: \(error)")
                    }
                }
                
                task.resume()
            } else {
                completion(localUrl)
            }
        }
    }
    
    static func fetchPaperText(_ paper: ArxivPaper, completion: @escaping (String?) -> Void) {
        fetchPaper(paper) { url in
            if let url = url, let pdfDocument = PDFDocument(url: url) {
                    
                var allText = ""
                
                for pageIndex in 0..<pdfDocument.pageCount {
                    guard let page = pdfDocument.page(at: pageIndex) else { continue }
                    if let pageText = page.string {
                        allText.append(pageText)
                    }
                }
                
                print(allText)
                
                completion(allText)
            } else {
                completion(nil)
            }
        }
    }
    
    static let arxivCitationRegex = /arXiv:(\d{4}\.\d{4,5})(v\d+)?/
    
    static func fetchPaperCitations(_ paper: ArxivPaper, completion: @escaping ([String]?) -> Void) {
        fetchPaperText(paper) { text in
            if let text = text {
                let matches = text.matches(of: arxivCitationRegex).map { match in
                    String(match.output.1)
                }
                completion(matches)
            } else {
                completion(nil)
            }
        }
    }
}
