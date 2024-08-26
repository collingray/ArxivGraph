import SwiftUI
import SwiftData

@main
struct ArxivGraphApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }.modelContainer(for: [CanvasPaper.self, CanvasImage.self])
    }
}
