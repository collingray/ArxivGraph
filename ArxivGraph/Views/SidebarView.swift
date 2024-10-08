import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(\.modelContext) private var model

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
                            canvasPosition = -paper.position
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                model.delete(paper)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .collapsible(false)
        }
        .safeAreaInset(edge: .top) {
            HStack {
                TextField("Search local papers", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }.padding(.horizontal)
        }
        .toolbar {
            ToolbarItemGroup {
                Spacer()
                Button {
                    if let url = PDFUtils.documentDir {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Image(systemName: "folder")
                        .imageScale(.large)
                }
                .help("Open papers directory")
                
                Button {
                    showAddPaperSheet = true
                } label: {
                    Image(systemName: "plus")
                        .imageScale(.large)
                }
                .help("Add a new paper")
            }
        }
    }
}

#Preview {
    NavigationSplitView {
        SidebarView(showAddPaperSheet: .constant(false), canvasPosition: .constant(.zero))
            .injectPreviewData()
    } detail: {
        Text("detail")
    }
}
