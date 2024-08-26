import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var manager: ModelManager?

    @Query private var papers: [CanvasPaper]
    
    @State var searchText: String = ""
    
    @Binding var showAddPaperSheet: Bool
    @Binding var canvasPosition: CGPoint
    
    var body: some View {
        List {
            Section {
                ForEach(papers.filter { paper in
                    searchText.isEmpty || paper.paper.title.lowercased().contains(searchText.lowercased())
                }) { paper in
                    Text(paper.paper.title)
                        .padding(3)
                        .onTapGesture(count: 2) {
                            PDFUtils.fetchPaper(paper.paper) { url in
                                if let url = url {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                        }
                        .onTapGesture(count: 1) {
                            canvasPosition = paper.position
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                manager?.removePaper(id: paper.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            } header: {
                HStack {
                    TextField("Search local papers", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button {
                        if let url = PDFUtils.documentDir {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "folder")
                            .imageScale(.large)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("Open papers directory")
                    
                    Button {
                        showAddPaperSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .imageScale(.large)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("Add a new paper")
                }
                .padding()
            }.collapsible(false)
        }
        .listStyle(.inset)
        .onAppear {
            manager = ModelManager(modelContext: modelContext)
        }
    }
}

#Preview {
    SidebarView(showAddPaperSheet: .constant(false), canvasPosition: .constant(.zero))
        .frame(width: 300, height: 600)
        .injectPreviewData()
}
