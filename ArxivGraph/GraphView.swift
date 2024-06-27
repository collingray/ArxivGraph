//
//  GraphView.swift
//  ArxivGraph
//
//  Created by Collin Gray on 6/26/24.
//

import SwiftUI

struct GraphView: View {
    @ObservedObject var viewModel: GraphViewModel
    
    @State var currentlyDragging: String? = nil
    @State var dragOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(viewModel.papers) { paper in
                    let citations = paper.citations.filter { viewModel.containsPaper(identifier: $0.id) }
                    
                    let horizontalOffset = (geometry.frame(in: .local).width / 2) - 150
                    
                    let start = viewModel.paperPositions[paper.id]!
                    let offsetStart = CGPoint(
                        x: start.x + (currentlyDragging == paper.id ? dragOffset.width : 0) + horizontalOffset,
                        y: start.y + (currentlyDragging == paper.id ? dragOffset.height : 0)
                    )
                    
                    ForEach(citations) { cited in
                        let end = viewModel.paperPositions[cited.id]!
                        let offsetEnd = CGPoint(
                            x: end.x + (currentlyDragging == cited.id ? dragOffset.width : 0) + horizontalOffset,
                            y: end.y + (currentlyDragging == cited.id ? dragOffset.height : 0)
                        )
                        
                        
                        Line(startPoint: offsetStart, endPoint: offsetEnd)
                            .stroke(Color.blue, lineWidth: 2)
                    }
                }
                
                ForEach(viewModel.papers) { paper in
                    let position = viewModel.paperPositions[paper.id]!
                    let offsetPosition = CGPoint(
                        x: position.x + (currentlyDragging == paper.id ? dragOffset.width : 0),
                        y: position.y + (currentlyDragging == paper.id ? dragOffset.height : 0)
                    )
                    
                    PaperNodeView(paper: paper, viewModel: viewModel)
                        .position(offsetPosition)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    currentlyDragging = paper.id
                                    dragOffset = value.translation
                                }
                                .onEnded { value in
                                    currentlyDragging = nil
                                    dragOffset = .zero
                                    viewModel.updatePosition(for: paper.id, by: value.translation)
                                }
                        )
                        .frame(width: 300)
                }
            }
        }
        .frame(minWidth: 600, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
    }
}

struct Line: Shape {
    var startPoint: CGPoint
    var endPoint: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        return path
    }
}

#Preview {
    GraphView(viewModel: PreviewData.graphViewModel)
}
