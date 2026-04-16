import Foundation

class SpiroCircle: SpiroGuide {
    static let defaultHoleDistance: Double = 1.0 / (2.0 * Double.pi)
    static let invisibleHolesToEdge: Int = 7

    var outerNotchCircumference: Int = 0
    var storedHoleNumber: Int = 1
    var startingNotch: Int = 0

    var outerCircumference: Double { Double(outerNotchCircumference) * notchSize }
    var outerRadius: Double { outerCircumference / (2.0 * Double.pi) }
    var angleIncrement: Double {
        outerNotchCircumference > 0 ? 360.0 / Double(outerNotchCircumference) : 0
    }
    var holeDistance: Double { Self.defaultHoleDistance * notchSize }
    var originalAngle: Double { angleIncrement * Double(startingNotch) }
    var holeNumber: Int { storedHoleNumber + Self.invisibleHolesToEdge }
    var penRadius: Double { outerRadius - Double(holeNumber) * holeDistance }

    // Override points for SpiroRing
    var notchCircumference: Int { outerNotchCircumference }
    var stationaryRadius: Double { outerRadius }

    func centerToCenterRadius(penGuide: SpiroCircle) -> Double {
        outerRadius + penGuide.outerRadius
    }
}
