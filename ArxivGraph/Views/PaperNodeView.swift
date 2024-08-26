import SwiftUI
import PDFKit
import SwiftData

struct PaperNodeView: View {
    let paper: CanvasPaper
    
    @Environment(\.modelContext) private var modelContext
        
    @State private var showingPreview = false
    @State private var showingPopover = false
    
    @Binding var canvasPosition: CGPoint
    
    @Query private var papers: [CanvasPaper]
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button {
                    showingPreview = true
                } label: {
                    Image(systemName: "eye")
                }.help("Preview paper")
                
                Button {
                    openPDF()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }.help("Open paper")
                
                Link(destination: URL(string: "http://arxiv.org/abs/\(paper.id)")!) {
                    Image(systemName: "link")
                }.help("Open on arXiv")
                
                Button {
                    showingPopover = true
                } label: {
                    Image(systemName: "text.quote")
                }.popover(isPresented: $showingPopover) {
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(paper.citations) { citation in
                                HStack {
                                    let existing = papers.contains(where: { $0.id == citation.id })
                                    
                                    Button {
                                        Task {
                                            try await modelContext.addPaper(identifier: citation.id, position: canvasPosition)
                                        }
                                    } label: {
                                        Image(systemName: existing ? "checkmark" : "plus")
                                            .frame(width: 15, height: 15)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    .disabled(existing)
                                    
                                    Spacer()
                                    Text(citation.title).multilineTextAlignment(.center)
                                    Spacer()
                                }
                            }
                        }.padding()
                    }.frame(minWidth: 350, maxWidth: 350, minHeight: 100, maxHeight: 250)
                }.help("Show cited papers")
                
                Button {
                    printPDF()
                } label: {
                    Image(systemName: "printer")
                }.help("Print paper")
                
                Spacer()
                                
                Button {
                    modelContext.delete(paper)
                } label: {
                    Image(systemName: "trash")
                }.help("Delete paper")
            }.buttonStyle(BorderlessButtonStyle())
            
            Text(paper.paper.title)
                .font(.headline)
            
            
            let dateFormatter = {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM yyyy"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                return formatter
            }()
            
            let formattedDate = dateFormatter.string(from: paper.paper.date)
            
            Text("arXiv: \(paper.id)  •  \(formattedDate)")
                .font(.subheadline)
            
            Text(paper.paper.authors.joined(separator: "  •  "))
                .font(.caption2)
                .lineLimit(5)
            
            Text(paper.paper.abstract.replacingOccurrences(of: "\n", with: " "))
                .font(.caption)
                .lineLimit(15)
                
        }
        .padding()
        .background()
        .cornerRadius(8)
        .shadow(radius: 4)
        .onTapGesture(count: 2) {
            openPDF()
        }
        .sheet(isPresented: $showingPreview) {
            PDFPreviewView(title: paper.paper.title, url: paper.paper.pdfUrl, isShown: $showingPreview)
                .frame(width: 600, height: 800)
        }
    }
    
    func openPDF() {
        PDFUtils.openPaper(paper.paper)
    }
    
    func printPDF() {
        PDFUtils.printPaper(paper.paper)
    }
}

struct PDFPreviewView: View {
    let title: String
    let url: URL
    @Binding var isShown: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                PDFViewer(url: url)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(Text(title))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isShown = false
                    }
                }
            }
        }
    }
}

struct PDFViewer: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {}
}

#Preview {
    PaperNodeView(paper: PreviewData.samplePaper, canvasPosition: .constant(.zero))
        .injectPreviewData()
}
