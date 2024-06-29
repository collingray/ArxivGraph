import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: GraphViewModel
    
    @State var showAddPaperSheet = false
    
    var body: some View {
        List {
            Section {
                ForEach(viewModel.papers.filter { paper in
                    viewModel.searchText.isEmpty || paper.title.lowercased().contains(viewModel.searchText.lowercased())
                }) { paper in
                    Text(paper.title)
                        .padding(3)
                        .onTapGesture(count: 2) {
                            PDFUtils.fetchPaper(paper) { url in
                                if let url = url {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                        }
                        .onTapGesture(count: 1) {
                            viewModel.centerOn(id: paper.id)
                        }
                }
            } header: {
                HStack {
                    TextField("Search local papers", text: $viewModel.searchText)
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
        .sheet(isPresented: $showAddPaperSheet) {
            AddPaperSheetView(viewModel: viewModel, isDisplayed: $showAddPaperSheet)
        }
    }
}

#Preview {
    SidebarView(viewModel: PreviewData.graphViewModel)
}
