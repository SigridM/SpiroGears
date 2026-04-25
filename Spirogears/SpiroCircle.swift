import Foundation

class SpiroCircle: SpiroGuide {
    static let defaultHoleDistance: Double = 1.0 / (2.0 * Double.pi)
    static let invisibleHolesToEdge: Int = 7

    var outerNotchCircumference: Int = 0
    var storedHoleNumber: Int = 1
    var startingNotch: Int = 1

    var outerCircumference: Double { Double(outerNotchCircumference) * notchSize }
    var outerRadius: Double { outerCircumference / (2.0 * Double.pi) }
    var angleIncrement: Double {
        outerNotchCircumference > 0 ? 360.0 / Double(outerNotchCircumference) : 0
    }
    var holeDistance: Double { Self.defaultHoleDistance * notchSize }
    var originalAngle: Double { angleIncrement * Double(startingNotch - 1) }
    var holeNumber: Int { storedHoleNumber + Self.invisibleHolesToEdge }

    // Pen radius: hole 1 sits just inside the tooth root; hole maxHole sits near center.
    // Matches the visual hole positions drawn by GearOverlayView.
    var penRadius: Double {
        let maxH   = max(1, outerNotchCircumference / 2 - SpiroCircle.invisibleHolesToEdge)
        let firstR = outerRadius - notchSize / .pi
        let stepR  = firstR / Double(maxH)
        return firstR - Double(storedHoleNumber - 1) * stepR
    }

    // Override points for SpiroRing
    var notchCircumference: Int { outerNotchCircumference }
    var stationaryRadius: Double { outerRadius }

    func centerToCenterRadius(penGuide: SpiroCircle) -> Double {
        outerRadius + penGuide.outerRadius
    }
}
