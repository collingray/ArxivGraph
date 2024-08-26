import SwiftUI
import SwiftData

struct GraphView: View {
    @Environment(\.modelContext) private var model
    
    @Query private var papers: [CanvasPaper]
    @Query private var images: [CanvasImage]
    
    @Binding var canvasPosition: CGPoint
    
    @State var draggingCanvas: Bool = false
    @State var draggingObjectId: String? = nil
    @State var dragOffset: CGPoint = CGPoint.zero
    
    @State var maxZ: Double = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            let centerOffset = CGPoint(x: 0, y: (geometry.frame(in: .local).height / 2))
            
            ZStack {
                Color.clear
                
                ForEach(papers) { paper in
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
                                    if paper.zIndex != maxZ {
                                        maxZ += 1
                                        paper.zIndex = maxZ
                                    }
                                    
                                    draggingObject(paper, by: value.translation)
                                })
                                .onEnded({ _ in
                                    paper.position += dragOffset
                                    objectDraggingEnded()
                                })
                        )
                        .zIndex(paper.zIndex)
                        .frame(width: 300)
                }
                
                ForEach(images) { image in
                    if let nsimage = image.image {
                        ResizableImageView(nsImage: nsimage)
                            .position(positionOf(image) + centerOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged({ value in
                                        if image.zIndex != maxZ {
                                            maxZ += 1
                                            image.zIndex = maxZ
                                        }
                                        
                                        draggingObject(image, by: value.translation)
                                    })
                                    .onEnded({ _ in
                                        image.position += dragOffset
                                        objectDraggingEnded()
                                    })
                            )
                            .contextMenu {
                                Button(role: .destructive) {
                                    model.delete(image)
                                } label: {
                                    Text("Remove")
                                }
                            }
                            .zIndex(image.zIndex)
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
                            model.insert(CanvasImage(image, position: location))
                        }
                    }
                }
                return true
            }
            return false
        }
        .frame(minWidth: 600, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
        .onAppear {
            maxZ = max(papers.map({$0.zIndex}).max() ?? 0.0, images.map({$0.zIndex}).max() ?? 0.0)
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
    
    func draggingObject(_ object: any CanvasObject, by offset: CGSize) {
        dragOffset = CGPoint(x: offset.width, y: offset.height)
        draggingObjectId = object.id
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
    
    static func += (left: inout CGPoint, right: CGPoint) {
        left = left + right
    }
}

#Preview {
    GraphView(canvasPosition: .constant(.zero))
        .injectPreviewData()
}
