import Foundation

class SpiroWheel: SpiroCircle {

    // MARK: - Factories

    static func example() -> SpiroWheel { wheel(notches: 80, hole: 25) }
    static func example2() -> SpiroWheel { wheel(notches: 36, hole: 1) }
    static func example3() -> SpiroWheel { wheel(notches: 63, hole: 1) }

    // 63-notch wheels
    static func example631()  -> SpiroWheel { wheel(notches: 63, hole: 1) }
    static func example633()  -> SpiroWheel { wheel(notches: 63, hole: 3) }
    static func example635()  -> SpiroWheel { wheel(notches: 63, hole: 5) }
    static func example637()  -> SpiroWheel { wheel(notches: 63, hole: 7) }
    static func example639()  -> SpiroWheel { wheel(notches: 63, hole: 9) }
    static func example6311() -> SpiroWheel { wheel(notches: 63, hole: 11) }
    static func example6313() -> SpiroWheel { wheel(notches: 63, hole: 13) }
    static func example6315() -> SpiroWheel { wheel(notches: 63, hole: 15) }
    static func example6317() -> SpiroWheel { wheel(notches: 63, hole: 17) }

    // 64-notch wheels
    static func example641()  -> SpiroWheel { wheel(notches: 64, hole: 1) }
    static func example643()  -> SpiroWheel { wheel(notches: 64, hole: 3) }
    static func example645()  -> SpiroWheel { wheel(notches: 64, hole: 5) }
    static func example647()  -> SpiroWheel { wheel(notches: 64, hole: 7) }
    static func example649()  -> SpiroWheel { wheel(notches: 64, hole: 9) }
    static func example6411() -> SpiroWheel { wheel(notches: 64, hole: 11) }
    static func example6413() -> SpiroWheel { wheel(notches: 64, hole: 13) }
    static func example6415() -> SpiroWheel { wheel(notches: 64, hole: 15) }
    static func example6417() -> SpiroWheel { wheel(notches: 64, hole: 17) }
    static func example6419() -> SpiroWheel { wheel(notches: 64, hole: 19) }
    static func example6421() -> SpiroWheel { wheel(notches: 64, hole: 21) }
    static func example6423() -> SpiroWheel { wheel(notches: 64, hole: 23) }
    static func example6425() -> SpiroWheel { wheel(notches: 64, hole: 25) }

    private static func wheel(notches: Int, hole: Int) -> SpiroWheel {
        let w = SpiroWheel(); w.outerNotchCircumference = notches; w.storedHoleNumber = hole; return w
    }
}
