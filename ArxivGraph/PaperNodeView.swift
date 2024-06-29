import SwiftUI
import PDFKit

struct PaperNodeView: View {
    let paper: ArxivPaper
    
    @ObservedObject var viewModel: GraphViewModel
    
    @State private var showingPreview = false
    @State private var showingPopover = false
    
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
                    print("\(paper.citations.count)")
                } label: {
                    Image(systemName: "text.quote")
                }.popover(isPresented: $showingPopover) {
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(paper.citations) { citation in
                                HStack {
                                    let existing = viewModel.containsPaper(identifier: citation.id)
                                    
                                    Button {
                                        viewModel.addPaper(identifier: citation.id)
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
                
                Spacer()
                
                Button {
                    viewModel.removePaper(identifier: paper.id)
                } label: {
                    Image(systemName: "trash")
                }.help("Delete paper")
            }.buttonStyle(BorderlessButtonStyle())
            
            Text(paper.title)
                .font(.headline)
            
            
            let dateFormatter = {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM yyyy"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                return formatter
            }()
            
            let formattedDate = dateFormatter.string(from: paper.date)
            
            Text("arXiv: \(paper.id)  •  \(formattedDate)")
                .font(.subheadline)
            
            Text(paper.authors.joined(separator: "  •  "))
                .font(.caption2)
                .lineLimit(5)
            
            Text(paper.abstract.replacingOccurrences(of: "\n", with: " "))
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
            PDFPreviewView(title: paper.title, url: paper.pdfUrl, isShown: $showingPreview)
                .frame(width: 600, height: 800)
        }
    }
    
    func openPDF() {
        PDFUtils.fetchPaper(paper) { url in
            if let url = url {
                NSWorkspace.shared.open(url)
            }
        }
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
    PaperNodeView(paper: PreviewData.paper4, viewModel: PreviewData.graphViewModel)
}
