//
//  AddPaperSheetView.swift
//  ArxivGraph
//
//  Created by Collin Gray on 6/26/24.
//

import SwiftUI

struct AddPaperSheetView: View {
    @ObservedObject var viewModel: GraphViewModel
    
    @Binding var isDisplayed: Bool
    
    @State var searchText: String = ""

    var body: some View {
        VStack {
            TextField(text: $searchText, prompt: Text("URL or ID")) {
                Text("Enter URL or ID")
            }.onSubmit {
                viewModel.addPaper(identifier: searchText)
                isDisplayed = false
            }
            
            HStack {
                Spacer()
                
                Button("Cancel", role: .cancel) {
                    isDisplayed = false
                }
                
                Button("Add Paper") {
                    viewModel.addPaper(identifier: searchText)
                    isDisplayed = false
                }
                .disabled(searchText.isEmpty)
            }
        }.padding()
    }
}

#Preview {
    AddPaperSheetView(viewModel: GraphViewModel(), isDisplayed: Binding(get: { false }, set: { _ in () }))
}
