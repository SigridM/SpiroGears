import SwiftUI

struct SpiroDialogData {
    var innerRingNotches: Int = 105
    var wheelNotches: Int = 24
    var color: Color = .black
    var holeNumber: Int = 1
    var startingNotch: Int = 0

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
        SpiroLayer(penColor: UIColor(color), penGuide: makeWheel(), stationaryGuide: makeRing())
    }
}

extension SpiroDialogData {
    init(from layer: SpiroLayer) {
        innerRingNotches = layer.stationaryGuide.innerNotchCircumference
        wheelNotches     = layer.penGuide.outerNotchCircumference
        holeNumber       = layer.penGuide.storedHoleNumber
        startingNotch    = layer.stationaryGuide.startingNotch
        color            = Color(uiColor: layer.penColor)
    }
}
