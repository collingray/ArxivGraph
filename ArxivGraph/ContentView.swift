//
//  ContentView.swift
//  ArxivGraph
//
//  Created by Collin Gray on 6/26/24.
//

import SwiftUI
import Combine
import PDFKit


struct ContentView: View {
    @ObservedObject var viewModel: GraphViewModel
    
    var body: some View {
        HSplitView {
            SidebarView(viewModel: viewModel)
                .frame(minWidth: 100, maxWidth: 500)
                
            GraphView(viewModel: viewModel)
                .frame(minWidth: 500)
        }
    }
}


#Preview {
    ContentView(viewModel: PreviewData.graphViewModel)
}
