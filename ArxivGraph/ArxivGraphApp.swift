//
//  ArxivGraphApp.swift
//  ArxivGraph
//
//  Created by Collin Gray on 6/26/24.
//

import SwiftUI

@main
struct ArxivGraphApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: GraphViewModel())
        }
    }
}
