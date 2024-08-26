import SwiftUI
import Combine
import PDFKit


struct ContentView: View {
    @State var showAddPaperSheet: Bool = false
    @State var canvasPosition: CGPoint = .zero
    
    var body: some View {
        NavigationSplitView {
            SidebarView(showAddPaperSheet: $showAddPaperSheet, canvasPosition: $canvasPosition)
                .frame(minWidth: 100, maxWidth: 500)
        } detail: {
            GraphView(canvasPosition: $canvasPosition)
                .frame(minWidth: 500)
                .onTapGesture(count: 2) {
                    showAddPaperSheet.toggle()
                }
        }.sheet(isPresented: $showAddPaperSheet) {
            AddPaperSheetView(isDisplayed: $showAddPaperSheet, canvasPosition: $canvasPosition)
        }
    }
}


#Preview {
    ContentView()
        .injectPreviewData()
}
