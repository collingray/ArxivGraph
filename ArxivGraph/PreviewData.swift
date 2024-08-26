import SwiftUI
import SwiftData

struct PreviewData {
    static let samplePaper: CanvasPaper = CanvasPaper(ArxivPaper(id: "2201.00001", title: "Quantum Computing Advances", abstract: "...", authors: ["Alice Quantum"], date: Date(), pdfUrl: URL(string: "https://arxiv.org/abs/2201.00001")!), position: CGPoint(x: 100, y: 100))
    
    static let samplePapers: [CanvasPaper] = [
        samplePaper,
        CanvasPaper(ArxivPaper(id: "2201.00002", title: "Machine Learning in Physics", abstract: "...", authors: ["Bob Neural"], date: Date(), pdfUrl: URL(string: "https://arxiv.org/abs/2201.00002")!), position: CGPoint(x: 300, y: 200)),
        // Add more sample papers as needed
    ]
}

@MainActor
let previewContainer: ModelContainer = {
    do {
        let container = try ModelContainer(
            for: CanvasPaper.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        
        for paper in PreviewData.samplePapers {
            container.mainContext.insert(paper)
        }
        
        return container
    } catch {
        fatalError("Failed to create preview container: \(error.localizedDescription)")
    }
}()

// 2. Create a preview modifier
struct PreviewContainerModifier: ViewModifier {
    @State private var dataInjected = false
    
    func body(content: Content) -> some View {
        content
            .modelContainer(previewContainer)
            .onAppear {
                if !dataInjected {
                    // You can add any additional setup here if needed
                    dataInjected = true
                }
            }
    }
}

// 3. Create an extension on View for easy application of the modifier
extension View {
    func injectPreviewData() -> some View {
        self.modifier(PreviewContainerModifier())
    }
}
