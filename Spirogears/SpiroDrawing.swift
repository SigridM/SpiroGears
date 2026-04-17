import UIKit

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
        for layer in layers {
            let path = layer.path(in: rect)
            context.setStrokeColor(layer.penColor.cgColor)
            context.setLineWidth(1.0)
            context.addPath(path.cgPath)
            context.strokePath()
        }
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
