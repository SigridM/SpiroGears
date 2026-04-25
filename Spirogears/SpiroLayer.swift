import UIKit

class SpiroLayer {
    var penColor: UIColor
    var penGuide: SpiroWheel
    var stationaryGuide: SpiroRing
    var offset: CGPoint

    // The step range actually drawn. drawnFrom defaults to 0; drawnTo defaults to
    // nil, which means the full stepCount. Manual drawing sets both at finalization.
    var drawnFrom: Int = 0
    var drawnTo: Int? = nil

    // Configured loop count (nil = full cycle). One loop = wheelN steps = one
    // complete rotation of the pen hole around the wheel center. Preserved so
    // "Use as Template" can restore the configured value even after drawnTo is
    // overwritten by manual drawing finalization.
    var loops: Int? = nil

    init(penColor: UIColor = .black,
         penGuide: SpiroWheel,
         stationaryGuide: SpiroRing,
         offset: CGPoint = .zero) {
        self.penColor = penColor
        self.penGuide = penGuide
        self.stationaryGuide = stationaryGuide
        self.offset = offset
    }

    func center(in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.midX + offset.x, y: rect.midY + offset.y)
    }

    // Total number of steps to complete one full cycle.
    var stepCount: Int {
        lcm(stationaryGuide.notchCircumference, penGuide.notchCircumference)
    }

    // Steps per loop: one full pen-hole orbit brings the drawing back near the start.
    // One wheel rotation = wheelN steps, but the pen only returns near its starting
    // direction every 2 wheel rotations (the hole completes a full cycle of the
    // relative angle), so stepsPerLoop = 2 × wheelN.
    var stepsPerLoop: Int { 2 * penGuide.outerNotchCircumference }

    // Total loops in a full cycle (ceiling, since stepCount may not be an exact multiple).
    var totalLoops: Int {
        let spl = stepsPerLoop
        return spl > 0 ? Int(ceil(Double(stepCount) / Double(spl))) : 0
    }

    // Step count to draw: loops × stepsPerLoop if loops is configured, else full stepCount.
    var effectiveEndStep: Int {
        guard let n = loops, n > 0 else { return stepCount }
        return min(n * stepsPerLoop, stepCount)
    }

    // Pen position at a given step, in the coordinate space of rect.
    func point(at step: Int, in rect: CGRect) -> CGPoint {
        let v1Len = stationaryGuide.centerToCenterRadius(penGuide: penGuide)
        let v2Len = penGuide.penRadius
        let c     = center(in: rect)
        func toRad(_ deg: Double) -> Double { deg * .pi / 180.0 }
        let thetaDeg = stationaryGuide.angleIncrement * Double(step) + stationaryGuide.originalAngle - 90.0
        let alphaDeg = -penGuide.angleIncrement * Double(step) + thetaDeg
        return CGPoint(
            x: v1Len * cos(toRad(thetaDeg)) + v2Len * cos(toRad(alphaDeg)) + c.x,
            y: v1Len * sin(toRad(thetaDeg)) + v2Len * sin(toRad(alphaDeg)) + c.y
        )
    }

    // Port of drawLayerOn: — returns a path instead of drawing directly to a widget.
    // Respects drawnFrom/drawnTo so partial manual drawings redraw correctly.
    func path(in rect: CGRect) -> UIBezierPath {
        let from = drawnFrom
        let to   = drawnTo ?? stepCount
        guard from != to else { return UIBezierPath() }
        let path = UIBezierPath()
        path.move(to: point(at: from, in: rect))
        if to > from {
            for i in (from + 1)...to { path.addLine(to: point(at: i, in: rect)) }
        } else {
            for i in stride(from: from - 1, through: to, by: -1) {
                path.addLine(to: point(at: i, in: rect))
            }
        }
        return path
    }

    // MARK: - Factories

    static func example()  -> SpiroLayer { SpiroLayer(penColor: .red,    penGuide: .example(),  stationaryGuide: .example()) }
    static func example2() -> SpiroLayer { SpiroLayer(penColor: .green,  penGuide: .example2(), stationaryGuide: .example2()) }
    static func example3() -> SpiroLayer { SpiroLayer(penColor: .blue,   penGuide: .example2(), stationaryGuide: .example3()) }
    static func example4() -> SpiroLayer { SpiroLayer(penColor: .purple, penGuide: .example2(), stationaryGuide: .example4()) }
    static func example5() -> SpiroLayer { SpiroLayer(penColor: .green,  penGuide: .example2(), stationaryGuide: .example5()) }
    static func example6() -> SpiroLayer { SpiroLayer(penColor: .blue,   penGuide: .example2(), stationaryGuide: .example6()) }
    static func example7() -> SpiroLayer { SpiroLayer(penColor: .purple, penGuide: .example2(), stationaryGuide: .example7()) }
    static func example8() -> SpiroLayer { SpiroLayer(penColor: .green,  penGuide: .example2(), stationaryGuide: .example8()) }
    static func example9() -> SpiroLayer { SpiroLayer(penColor: .blue,   penGuide: .example2(), stationaryGuide: .example9()) }
    static func example10() -> SpiroLayer { SpiroLayer(penColor: .purple, penGuide: .example2(), stationaryGuide: .example10()) }
    static func example11() -> SpiroLayer { SpiroLayer(penColor: .green,  penGuide: .example3(), stationaryGuide: .example()) }
    static func example12() -> SpiroLayer { SpiroLayer(penColor: .black,  penGuide: .example3(), stationaryGuide: .example10()) }

    // A series: 63-notch wheel, 150/105 ring
    static func exampleA1() -> SpiroLayer { SpiroLayer(penColor: .blue,   penGuide: .example631(),  stationaryGuide: .example150105()) }
    static func exampleA2() -> SpiroLayer { SpiroLayer(penColor: .blue,   penGuide: .example633(),  stationaryGuide: .example150105()) }
    static func exampleA3() -> SpiroLayer { SpiroLayer(penColor: .blue,   penGuide: .example635(),  stationaryGuide: .example150105()) }
    static func exampleA4() -> SpiroLayer { SpiroLayer(penColor: .red,    penGuide: .example637(),  stationaryGuide: .example150105()) }
    static func exampleA5() -> SpiroLayer { SpiroLayer(penColor: .red,    penGuide: .example639(),  stationaryGuide: .example150105()) }
    static func exampleA6() -> SpiroLayer { SpiroLayer(penColor: .red,    penGuide: .example6311(), stationaryGuide: .example150105()) }
    static func exampleA7() -> SpiroLayer { SpiroLayer(penColor: .green,  penGuide: .example6313(), stationaryGuide: .example150105()) }
    static func exampleA8() -> SpiroLayer { SpiroLayer(penColor: .green,  penGuide: .example6315(), stationaryGuide: .example150105()) }
    static func exampleA9() -> SpiroLayer { SpiroLayer(penColor: .green,  penGuide: .example6317(), stationaryGuide: .example150105()) }

    // B series: 64-notch wheel, 144/96 ring
    static func exampleB1()  -> SpiroLayer { SpiroLayer(penColor: .black, penGuide: .example641(),  stationaryGuide: .example14496()) }
    static func exampleB2()  -> SpiroLayer { SpiroLayer(penColor: .black, penGuide: .example643(),  stationaryGuide: .example14496()) }
    static func exampleB3()  -> SpiroLayer { SpiroLayer(penColor: .black, penGuide: .example645(),  stationaryGuide: .example14496()) }
    static func exampleB4()  -> SpiroLayer { SpiroLayer(penColor: .red,   penGuide: .example647(),  stationaryGuide: .example14496()) }
    static func exampleB5()  -> SpiroLayer { SpiroLayer(penColor: .red,   penGuide: .example649(),  stationaryGuide: .example14496()) }
    static func exampleB6()  -> SpiroLayer { SpiroLayer(penColor: .red,   penGuide: .example6411(), stationaryGuide: .example14496()) }
    static func exampleB7()  -> SpiroLayer { SpiroLayer(penColor: .blue,  penGuide: .example6413(), stationaryGuide: .example14496()) }
    static func exampleB8()  -> SpiroLayer { SpiroLayer(penColor: .blue,  penGuide: .example6415(), stationaryGuide: .example14496()) }
    static func exampleB9()  -> SpiroLayer { SpiroLayer(penColor: .blue,  penGuide: .example6417(), stationaryGuide: .example14496()) }
    static func exampleB10() -> SpiroLayer { SpiroLayer(penColor: .green, penGuide: .example6419(), stationaryGuide: .example14496()) }
    static func exampleB11() -> SpiroLayer { SpiroLayer(penColor: .green, penGuide: .example6421(), stationaryGuide: .example14496()) }
    static func exampleB12() -> SpiroLayer { SpiroLayer(penColor: .green, penGuide: .example6423(), stationaryGuide: .example14496()) }
    static func exampleB13() -> SpiroLayer { SpiroLayer(penColor: .green, penGuide: .example6425(), stationaryGuide: .example14496()) }
}

// MARK: - Math helpers
private func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }
private func lcm(_ a: Int, _ b: Int) -> Int { (a == 0 || b == 0) ? 0 : abs(a / gcd(a, b) * b) }
