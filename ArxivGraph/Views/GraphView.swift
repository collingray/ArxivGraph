import SwiftUI
import SwiftData

struct GraphView: View {
//    @Environment(GraphViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @State private var manager: ModelManager?
    
    @Query private var papers: [CanvasPaper]
    @Query private var images: [CanvasImage]
    
    @Binding var canvasPosition: CGPoint
    
    @State var draggingCanvas: Bool = false
    @State var draggingObjectId: String? = nil
    @State var dragOffset: CGPoint = CGPoint.zero
    
    var body: some View {
        GeometryReader { geometry in
            let centerOffset = CGPoint(x: 0, y: (geometry.frame(in: .local).height / 2))
            
            ZStack {
                Color.clear
                
                ForEach(papers) { paper in
                    
//                    let citations = paper.paper.citations
//                        .filter { paper in
//                        !self.papers.contains(where: { $0.paper.id == paper.id })
//                    }
                    let citedIds = Set(paper.citations.map { $0.id })
                    let citations = papers.filter { cited in
                        citedIds.contains(cited.paper.id)
                    }
                    
                    let horizontalOffset = CGPoint(x: (geometry.frame(in: .local).width / 2) - 150, y: 0)
                    let start = positionOf(paper) + horizontalOffset + centerOffset
                    ForEach(citations) { cited in
                        let end = positionOf(cited) + horizontalOffset + centerOffset
                        
                        Connection(startPoint: start, endPoint: end)
                            .stroke(Color.blue, lineWidth: 2)
                    }
                }
                
                ForEach(papers) { paper in
                    PaperNodeView(paper: paper, canvasPosition: $canvasPosition)
                        .position(positionOf(paper) + centerOffset)
                        .gesture(
                            DragGesture()
                                .onChanged({ value in
                                    draggingObject(paper.id, by: value.translation )
                                    
//                                    if let i = papers.firstIndex(where: { $0.id == paper.id }), i != images.count - 1 {
//                                        papers.append(papers.remove(at: i))
//                                    }
                                })
                                .onEnded({ _ in
                                    manager?.movePaper(id: paper.id, newPosition: paper.position + dragOffset)
                                    objectDraggingEnded()
                                })
                        )
                        .frame(width: 300)
                }
                
                ForEach(images) { image in
                    if let nsimage = image.image {
                        ResizableImageView(nsImage: nsimage)
                            .position(positionOf(image) + centerOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged({ value in
                                        draggingObject(image.id, by: value.translation )
                                        
//                                        if let i = viewModel.images.firstIndex(where: { $0.hashValue == Int(imageId) }), i != viewModel.images.count - 1 {
//                                            viewModel.images.append(viewModel.images.remove(at: i))
//                                        }
                                    })
                                    .onEnded({ _ in
                                        manager?.movePaper(id: image.id, newPosition: image.position + dragOffset)
                                        objectDraggingEnded()
                                    })
                            )
                            .contextMenu {
                                Button(role: .destructive) {
                                    manager?.removeImage(id: image.id)
                                } label: {
                                    Text("Remove")
                                }
                            }
                    }
                }
            }
            .background(.windowBackground)
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        draggingCanvas(by: value.translation)
                    })
                    .onEnded({ _ in canvasDraggingEnded() })
            )
        }
        .onDrop(of: [.image], isTargeted: nil) { providers, location in
            if let item = providers.first {
                item.loadObject(ofClass: NSImage.self) { image, error in
                    if let image = image as? NSImage {
                        DispatchQueue.main.async {
                            manager?.addImage(CanvasImage(image, position: location))
                        }
                    }
                }
                return true
            }
            return false
        }
        .frame(minWidth: 600, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
        .onAppear {
            manager = ModelManager(modelContext: modelContext)
        }
    }
    
    
    func positionOf(_ object: any CanvasObject) -> CGPoint {
        
        let position = object.position + canvasPosition
        
        if draggingCanvas || draggingObjectId == object.id {
            return position + dragOffset
        } else {
            return position
        }
    }
    
    func draggingCanvas(by offset: CGSize) {
        dragOffset = CGPoint(x: offset.width, y: offset.height)
        draggingCanvas = true
    }
    
    func canvasDraggingEnded() {
        canvasPosition = canvasPosition + dragOffset
        dragOffset = .zero
        draggingCanvas = false
    }
    
    func draggingObject(_ id: String, by offset: CGSize) {
        dragOffset = CGPoint(x: offset.width, y: offset.height)
        draggingObjectId = id
    }
    
    func objectDraggingEnded() {
        dragOffset = .zero
        draggingObjectId = nil
    }
}

struct Connection: Shape {
    var startPoint: CGPoint
    var endPoint: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        return path
    }
}

extension CGPoint {
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
    
    static prefix func -(point: CGPoint) -> CGPoint {
        return CGPoint(x: -point.x, y: -point.y)
    }
}

//#Preview {
//    GraphView()
//}
