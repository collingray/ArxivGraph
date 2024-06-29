//
//  GraphView.swift
//  ArxivGraph
//
//  Created by Collin Gray on 6/26/24.
//

import SwiftUI

struct GraphView: View {
    @ObservedObject var viewModel: GraphViewModel
    
    var body: some View {
        GeometryReader { geometry in
            let centerOffset = CGPoint(x: 0, y: (geometry.frame(in: .local).height / 2))
            
            ZStack {
                ForEach(viewModel.papers) { paper in
                    let citations = paper.citations.filter { viewModel.containsPaper(identifier: $0.id) }
                    
                    let horizontalOffset = CGPoint(x: (geometry.frame(in: .local).width / 2) - 150, y: 0)
                    let start = viewModel.positionOf(id: paper.id) + horizontalOffset + centerOffset
                    ForEach(citations) { cited in
                        let end = viewModel.positionOf(id: cited.id) + horizontalOffset + centerOffset
                        
                        Line(startPoint: start, endPoint: end)
                            .stroke(Color.blue, lineWidth: 2)
                    }
                }
                
                ForEach(viewModel.papers) { paper in
                    PaperNodeView(paper: paper, viewModel: viewModel)
                        .position(viewModel.positionOf(id: paper.id) + centerOffset)
                        .gesture(
                            DragGesture()
                                .onChanged({ value in
                                    viewModel.paperDragging(paper.id, by: value.translation )
                                })
                                .onEnded({ _ in viewModel.paperDraggingEnded(paper.id) })
                        )
                        .frame(width: 300)
                }
            }
            .background(.windowBackground)
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        viewModel.canvasDragging(by: value.translation)
                    })
                    .onEnded({ _ in viewModel.canvasDraggingEnded() })
            )
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
