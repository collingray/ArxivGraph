import SwiftUI

@main
struct ArxivGraphApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: GraphViewModel())
        }
    }
}
