import SwiftUI
import SwiftData
import AppKit

protocol CanvasObject: Identifiable {
    var id: String { get }
    var position: CGPoint { get set }
}

@Model
final class CanvasPaper: CanvasObject, Identifiable {
    @Attribute var id: String
    @Attribute var paper: ArxivPaper
    @Attribute var citations: [ArxivPaper] = []
    
    var position: CGPoint {
        get {
            CGPoint(x: x, y: y)
        }
        set {
            x = newValue.x
            y = newValue.y
        }
    }
    @Attribute private var x: Double
    @Attribute private var y: Double
    
    init(_ paper: ArxivPaper, position: CGPoint) {
        self.id = paper.id
        self.paper = paper
        self.x = position.x
        self.y = position.y
    }
}

@Model
final class CanvasImage: CanvasObject, Identifiable {
    var id: String = UUID().uuidString
    
    private var imageData: Data?
    
    @Transient
    private var cachedImage: NSImage?
    
    var position: CGPoint {
        get {
            CGPoint(x: x, y: y)
        }
        set {
            x = newValue.x
            y = newValue.y
        }
    }
    @Attribute private var x: Double
    @Attribute private var y: Double
    
    var image: NSImage? {
        get {
            if cachedImage == nil {
                cachedImage = imageData.flatMap { NSImage(data: $0) }
            }
            return cachedImage
        }
        set {
            cachedImage = newValue
            imageData = newValue?.tiffRepresentation
        }
    }
    
    init(_ image: NSImage, position: CGPoint) {
        self.x = position.x
        self.y = position.y
        self.image = image
    }
}

extension CanvasImage {
    convenience init?(named name: String, position: CGPoint) {
        guard let image = NSImage(named: name) else { return nil }
        self.init(image, position: position)
    }
}
