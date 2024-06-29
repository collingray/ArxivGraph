import SwiftUI

struct ResizableImageView: View {
    @State private var imageSize: CGSize
    let image: Image
    let aspectRatio: CGFloat
    @State private var dragOffset: CGSize = .zero
    let minSize: CGFloat = 100  // Minimum size for either dimension
    @State private var isHovered = false

    init(nsImage: NSImage) {
        self.image = Image(nsImage: nsImage)
        self._imageSize = State(initialValue: nsImage.size)
        self.aspectRatio = nsImage.size.width / nsImage.size.height
    }

    var body: some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: imageSize.width, height: imageSize.height)
            .overlay(
                GeometryReader { geometry in
                    if isHovered || dragOffset != .zero {
                        ResizeHandles(
                            geometry: geometry,
                            dragOffset: $dragOffset,
                            onDragChanged: handleDrag,
                            onDragEnded: { _ in dragOffset = .zero }
                        )
                    }
                }
            )
            .padding()
            .onHover(perform: { hovered in
                isHovered = hovered
            })
    }

    private func handleDrag(_ translation: CGSize) {
        let delta = translation - dragOffset
        dragOffset = translation

        var newWidth = imageSize.width + delta.width
        var newHeight = imageSize.height + delta.height

        // Ensure minimum size
        newWidth = max(newWidth, minSize)
        newHeight = max(newHeight, minSize)

        // Preserve aspect ratio
        if abs(delta.width) > abs(delta.height) {
            newHeight = newWidth / aspectRatio
        } else {
            newWidth = newHeight * aspectRatio
        }

        imageSize = CGSize(width: newWidth, height: newHeight)
    }
}

struct ResizeHandles: View {
    let geometry: GeometryProxy
    @Binding var dragOffset: CGSize
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: (CGSize) -> Void
    
    @State var handleHovers: [HandlePosition: Bool] = [
        .topLeft: false,
        .topRight: false,
        .bottomLeft: false,
        .bottomRight: false,
    ]

    var body: some View {
        ZStack {
            ForEach(dragHandles, id: \.self) { handle in
                DragHandle(position: handle)
                    .gesture(
                        DragGesture()
                            .onChanged({ value in
                                onDragChanged(value.translation * handle.rotation)
                            })
                            .onEnded({ value in
                                onDragEnded(value.translation * handle.rotation)
                            })
                    )
            }
        }
    }

    private var dragHandles: [HandlePosition] {
        [.topLeft, .topRight, .bottomLeft, .bottomRight]
    }

    private func DragHandle(position: HandlePosition) -> some View {
        let isExpanded = handleHovers[position]!
        let circleSize: CGFloat = isExpanded ? 15 : 10
        
        return Circle()
            .fill(Color.blue)
            .frame(width: circleSize, height: circleSize)
            .position(position.point(in: geometry.size))
//            .onHover { hovered in
//                handleHovers[position] = hovered
//            }
//            .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

enum HandlePosition: CaseIterable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    func point(in size: CGSize) -> CGPoint {
        switch self {
        case .topLeft: return CGPoint(x: 0, y: 0)
        case .topRight: return CGPoint(x: size.width, y: 0)
        case .bottomLeft: return CGPoint(x: 0, y: size.height)
        case .bottomRight: return CGPoint(x: size.width, y: size.height)
        }
    }
    
    var rotation: CGSize {
        switch self {
        case .topLeft: return CGSize(width: -1, height: -1)
        case .topRight: return CGSize(width: 1, height: -1)
        case .bottomLeft: return CGSize(width: -1, height: 1)
        case .bottomRight: return CGSize(width: 1, height: 1)
        }
    }
}

extension CGSize {
    static func - (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
    
    static func *(lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width * rhs.width, height: lhs.height * rhs.height)
    }
}
