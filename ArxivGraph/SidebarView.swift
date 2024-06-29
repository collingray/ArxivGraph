//
//  SidebarView.swift
//  ArxivGraph
//
//  Created by Collin Gray on 6/26/24.
//

import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: GraphViewModel
    
    @State var showAddPaperSheet = false
    
    var body: some View {
        List {
            Section(header:
                HStack {
                    TextField("Search papers", text: $viewModel.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button {
                        showAddPaperSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }.buttonStyle(BorderlessButtonStyle())
                }
                .padding()
//                .listRowInsets(EdgeInsets())
            ) {
                ForEach(viewModel.papers.filter { paper in
                    viewModel.searchText.isEmpty || paper.title.lowercased().contains(viewModel.searchText.lowercased())
                }) { paper in
                    Text(paper.title)
                        .onTapGesture(count: 1) {
                            // todo
                        }
                        .onTapGesture(count: 2) {
                            PDFUtils.fetchPaper(paper) { url in
                                if let url = url {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                        }
                }
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
