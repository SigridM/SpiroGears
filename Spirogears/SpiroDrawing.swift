import UIKit
import SwiftUI

class SpiroDrawing {
    var layers: [SpiroLayer] = []

    private static var _savedDrawings: [String: SpiroDrawing] = [:]

    func addLayer(_ layer: SpiroLayer) {
        layers.append(layer)
    }

    @discardableResult
    func removeLastLayer() -> SpiroLayer? {
        layers.isEmpty ? nil : layers.removeLast()
    }

    func draw(in context: CGContext, rect: CGRect) {
        for layer in layers where !layer.isHidden {
            let path = layer.path(in: rect)
            context.setStrokeColor(layer.penColor.cgColor)
            context.setLineWidth(1.0)
            context.addPath(path.cgPath)
            context.strokePath()
        }
    }

    @discardableResult
    func removeLayer(at index: Int) -> SpiroLayer? {
        guard index >= 0, index < layers.count else { return nil }
        return layers.remove(at: index)
    }

    func insertLayer(_ layer: SpiroLayer, at index: Int) {
        layers.insert(layer, at: Swift.min(Swift.max(0, index), layers.count))
    }

    func moveLayer(from source: IndexSet, to destination: Int) {
        layers.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Saved drawings

    // Names reserved for built-in presets; cannot be overwritten by the user.
    static let presetNames: Set<String> = ["Circle", "Star", "Triangle"]

    static func save(_ drawing: SpiroDrawing, name: String) {
        _savedDrawings[name] = drawing
    }

    static var savedDrawingNames: [String] {
        _savedDrawings.keys.sorted()
    }

    static func savedDrawing(named name: String) -> SpiroDrawing? {
        _savedDrawings[name]
    }

    static func delete(name: String) {
        _savedDrawings.removeValue(forKey: name)
        _thumbnails.removeValue(forKey: name)
    }

    // MARK: - Thumbnails

    private static var _thumbnails: [String: UIImage] = [:]

    /// Renders a drawing into a square thumbnail image, fitting all content.
    static func generateThumbnail(for drawing: SpiroDrawing, size: CGFloat = 160) -> UIImage {
        // Use a large square to compute accurate path bounds.
        let computeSize: CGFloat = 1000
        let computeRect = CGRect(origin: .zero, size: CGSize(width: computeSize, height: computeSize))

        var contentBounds = CGRect.null
        for layer in drawing.layers where !layer.isHidden {
            let b = layer.path(in: computeRect).bounds
            if !b.isEmpty { contentBounds = contentBounds.union(b) }
        }

        // Build a square crop region centered on the content with a small padding margin.
        let cropRect: CGRect
        if contentBounds.isNull || contentBounds.isEmpty {
            cropRect = computeRect
        } else {
            let padding = max(contentBounds.width, contentBounds.height) * 0.04
            let padded = contentBounds.insetBy(dx: -padding, dy: -padding)
            let dim = max(padded.width, padded.height)
            cropRect = CGRect(x: padded.midX - dim / 2,
                              y: padded.midY - dim / 2,
                              width: dim, height: dim)
        }

        // Render the full drawing into a large UIImage (UIKit handles the coordinate flip).
        let fullImage = UIGraphicsImageRenderer(size: computeRect.size).image { ctx in
            UIColor.white.setFill()
            UIRectFill(computeRect)
            drawing.draw(in: ctx.cgContext, rect: computeRect)
        }

        // Draw the full image into the thumbnail rect positioned so cropRect fills the square.
        let s = size / cropRect.width   // cropRect is square, so width == height
        let drawRect = CGRect(x: -cropRect.minX * s, y: -cropRect.minY * s,
                              width: computeSize * s, height: computeSize * s)
        return UIGraphicsImageRenderer(size: CGSize(width: size, height: size)).image { _ in
            fullImage.draw(in: drawRect)
        }
    }

    static func saveThumbnail(_ thumbnail: UIImage, name: String) {
        _thumbnails[name] = thumbnail
    }

    /// Returns cached thumbnails for all saved drawings and presets,
    /// generating preset thumbnails on first access.
    static var allThumbnails: [String: UIImage] {
        let presetMap: [(String, () -> SpiroDrawing)] = [
            ("Circle",   { .example()  }),
            ("Star",     { .example4() }),
            ("Triangle", { .example5() })
        ]
        for (name, factory) in presetMap where _thumbnails[name] == nil {
            _thumbnails[name] = generateThumbnail(for: factory())
        }
        return _thumbnails
    }

    // MARK: - Factories

    static func example() -> SpiroDrawing {
        let d = SpiroDrawing()
        for layer in [SpiroLayer.example(), .example2(), .example3(), .example4(), .example5(),
                      .example6(), .example7(), .example8(), .example9(), .example10()] {
            d.addLayer(layer)
        }
        return d
    }

    static func example2() -> SpiroDrawing {
        let d = SpiroDrawing(); d.addLayer(.example11()); return d
    }

    static func example3() -> SpiroDrawing {
        let d = SpiroDrawing(); d.addLayer(.example12()); return d
    }

    static func example4() -> SpiroDrawing {
        let d = SpiroDrawing()
        for layer in [SpiroLayer.exampleA1(), .exampleA2(), .exampleA3(), .exampleA4(), .exampleA5(),
                      .exampleA6(), .exampleA7(), .exampleA8(), .exampleA9()] {
            d.addLayer(layer)
        }
        return d
    }

    static func example5() -> SpiroDrawing {
        let d = SpiroDrawing()
        for layer in [SpiroLayer.exampleB1(), .exampleB2(), .exampleB3(), .exampleB4(), .exampleB5(),
                      .exampleB6(), .exampleB7(), .exampleB8(), .exampleB9(), .exampleB10(),
                      .exampleB11(), .exampleB12(), .exampleB13()] {
            d.addLayer(layer)
        }
        return d
    }
}
