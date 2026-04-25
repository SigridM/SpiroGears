import SwiftUI

struct SpiroDialogData {
    var innerRingNotches: Int = 105
    var wheelNotches: Int = 24
    var color: Color = .black
    var holeNumber: Int = 1
    var startingNotch: Int = 0
    // nil = full cycle. One loop = 2 × wheelNotches steps (pen returns near start).
    var loops: Int? = nil

    static var lastData = SpiroDialogData()

    func makeRing() -> SpiroRing {
        let r = SpiroRing()
        r.innerNotchCircumference = innerRingNotches
        r.startingNotch = startingNotch
        return r
    }

    func makeWheel() -> SpiroWheel {
        let w = SpiroWheel()
        w.outerNotchCircumference = wheelNotches
        w.storedHoleNumber = holeNumber
        return w
    }

    func makeLayer() -> SpiroLayer {
        let layer = SpiroLayer(penColor: UIColor(color), penGuide: makeWheel(), stationaryGuide: makeRing())
        if let n = loops, n > 0 {
            layer.loops   = n
            layer.drawnTo = min(n * 2 * wheelNotches, layer.stepCount)
        }
        return layer
    }

    // Total loops for a full cycle with the current ring/wheel settings.
    // = ceil(lcm(ring, wheel) / (2 × wheel)) = ceil(ring / (2 × gcd(ring, wheel)))
    var totalLoops: Int {
        let g = gcd(innerRingNotches, wheelNotches)
        guard g > 0 else { return 0 }
        return Int(ceil(Double(innerRingNotches) / Double(2 * g)))
    }
}

extension SpiroDialogData {
    init(from layer: SpiroLayer) {
        innerRingNotches = layer.stationaryGuide.innerNotchCircumference
        wheelNotches     = layer.penGuide.outerNotchCircumference
        holeNumber       = layer.penGuide.storedHoleNumber
        startingNotch    = layer.stationaryGuide.startingNotch
        color            = Color(uiColor: layer.penColor)
        loops            = layer.loops
    }
}

private func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }
