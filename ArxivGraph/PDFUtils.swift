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
    
    static func openPaper(_ paper: ArxivPaper) {
        PDFUtils.fetchPaper(paper) { url in
            if let url = url {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    static func printPaper(_ paper: ArxivPaper) {
        Task {
            do {
                // Load the PDF document on a background thread
                let pdfDocument = try await Task.detached(priority: .userInitiated) {
                    guard let document = PDFDocument(url: paper.pdfUrl) else {
                        throw NSError(domain: "PDFPrinterError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create PDF document from URL"])
                    }
                    return document
                }.value
                
                // Switch to the main thread for UI operations
                await MainActor.run {
                    // Create a print info object
                    let printInfo = NSPrintInfo.shared
                    printInfo.topMargin = 0.0
                    printInfo.leftMargin = 0.0
                    printInfo.rightMargin = 0.0
                    printInfo.bottomMargin = 0.0
                    
                    // Create a print operation
                    guard let printOperation = pdfDocument.printOperation(for: printInfo, scalingMode: .pageScaleToFit, autoRotate: true) else {
                        print("Failed to create print operation")
                        return
                    }
                    
                    // Set up the print operation
                    printOperation.showsPrintPanel = true
                    printOperation.showsProgressPanel = true
                    
                    // Run the print operation
                    printOperation.run()
                }
            } catch {
                print("Error opening print dialog: \(error.localizedDescription)")
            }
        }
    }
}
