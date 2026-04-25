import Foundation

class SpiroRing: SpiroCircle {
    var innerNotchCircumference: Int = 0
    var innerGuide: Bool = true

    var innerCircumference: Double { Double(innerNotchCircumference) * notchSize }
    var innerRadius: Double { innerCircumference / (2.0 * Double.pi) }

    override var angleIncrement: Double {
        guard innerGuide, innerNotchCircumference > 0 else { return super.angleIncrement }
        return 360.0 / Double(innerNotchCircumference)
    }
    override var notchCircumference: Int {
        innerGuide ? innerNotchCircumference : super.notchCircumference
    }
    override var stationaryRadius: Double {
        innerGuide ? innerRadius : super.stationaryRadius
    }
    override func centerToCenterRadius(penGuide: SpiroCircle) -> Double {
        innerGuide ? innerRadius - penGuide.outerRadius : super.centerToCenterRadius(penGuide: penGuide)
    }

    // MARK: - Factories

    static func example() -> SpiroRing {
        let r = SpiroRing(); r.innerNotchCircumference = 155; return r
    }
    static func example2() -> SpiroRing {
        let r = SpiroRing(); r.innerNotchCircumference = 145; return r
    }
    static func example3() -> SpiroRing {
        let r = example2(); r.startingNotch = 6; return r
    }
    static func example4() -> SpiroRing {
        let r = example2(); r.startingNotch = 11; return r
    }
    static func example5() -> SpiroRing {
        let r = example2(); r.startingNotch = 16; return r
    }
    static func example6() -> SpiroRing {
        let r = example2(); r.startingNotch = 21; return r
    }
    static func example7() -> SpiroRing {
        let r = example2(); r.startingNotch = 26; return r
    }
    static func example8() -> SpiroRing {
        let r = example2(); r.startingNotch = 31; return r
    }
    static func example9() -> SpiroRing {
        let r = example2(); r.startingNotch = 36; return r
    }
    static func example10() -> SpiroRing {
        let r = SpiroRing(); r.innerNotchCircumference = 145; r.startingNotch = 41; return r
    }
    static func example150105() -> SpiroRing {
        let r = SpiroRing(); r.innerNotchCircumference = 105; return r
    }
    static func example14496() -> SpiroRing {
        let r = SpiroRing(); r.innerNotchCircumference = 96; return r
    }
    static func example210300() -> SpiroRing {
        let r = SpiroRing(); r.innerNotchCircumference = 210; return r
    }
}
