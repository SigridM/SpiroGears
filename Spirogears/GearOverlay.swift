import SwiftUI

// MARK: - Gear overlay rendered via SwiftUI Canvas, layered above the spiral drawing.
// Draws the stationary ring and the rolling wheel for the given layer.
// wheelAngle is the wheel-center's angle around the ring center, in degrees from top (0 = top).

private let gearFill      = Color(white: 0.90)
private let gearGradLeft  = Color(white: 0.84)
private let gearGradRight = Color(white: 0.96)
private let gearStroke    = Color(white: 0.60)   // noticeably darker so edges read against the fill
private let holeGradLeft  = Color(white: 0.76)
private let holeGradRight = Color(white: 0.92)
private let holeStroke    = Color(white: 0.45)   // dark enough to make each hole clearly visible
private let ringBandWidth: CGFloat = 14           // visible ring thickness in points

struct GearOverlayView: View {
    let layer: SpiroLayer
    var wheelAngle: Double = 0

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width  / 2 + layer.offset.x,
                                 y: size.height / 2 + layer.offset.y)
            drawRing(layer.stationaryGuide, center: center, context: &context)
            drawWheel(layer.penGuide, around: layer.stationaryGuide,
                      center: center, angle: wheelAngle, context: &context)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Ring

    private func drawRing(_ ring: SpiroRing, center: CGPoint, context: inout GraphicsContext) {
        // Display the ring as a thin band around its inner (working) edge only.
        // The outer notch count is irrelevant when drawing inside the ring, so we
        // use innerRadius + ringBandWidth as the visible outer boundary.
        let displayOuterR = CGFloat(ring.innerRadius) + ringBandWidth
        let innerR = CGFloat(ring.innerRadius)
        let depth  = CGFloat(ring.notchSize * 2 / .pi)
        let count  = ring.innerNotchCircumference

        context.drawLayer { ctx in
            ctx.opacity = 0.63

            let disk = Path(ellipseIn: centeredRect(at: center, radius: displayOuterR))
            ctx.fill(disk, with: .color(gearFill))
            applyGradient(to: disk, center: center, radius: displayOuterR, context: &ctx)
            ctx.stroke(disk, with: .color(gearStroke), lineWidth: 0.2)

            // Cut inner hole with inward-tooth profile
            let cut = innerCutPath(center: center, innerRadius: innerR,
                                   notchCount: count, toothDepth: depth)
            ctx.blendMode = .destinationOut
            ctx.fill(cut, with: .color(.white))
        }
    }

    // MARK: - Wheel

    private func drawWheel(_ wheel: SpiroWheel, around ring: SpiroRing,
                            center: CGPoint, angle: Double,
                            context: inout GraphicsContext) {
        // The drawing formula (SpiroLayer.path) at step i gives:
        //   thetaDeg (wheel center) = ring.angleIncrement × i + originalAngle − 90
        //   alphaDeg (hole dir)     = −wheel.angleIncrement × i + thetaDeg
        //                           = angle × (1 − ringInner/wheelOuter) + originalAngle − 90
        // where angle = ring.angleIncrement × i.  Both use originalAngle as a fixed offset.
        let originDeg = ring.originalAngle                          // startingNotch offset in degrees
        let count     = wheel.outerNotchCircumference
        let ratio     = Double(ring.innerNotchCircumference) / Double(count)

        let dist = CGFloat(ring.centerToCenterRadius(penGuide: wheel))
        let rad  = (angle + originDeg - 90) * .pi / 180
        let wc   = CGPoint(x: center.x + dist * CGFloat(cos(rad)),
                           y: center.y + dist * CGFloat(sin(rad)))

        let outerR = CGFloat(wheel.outerRadius)
        let depth  = CGFloat(wheel.notchSize * 2 / .pi)

        let spinDeg = angle * (1.0 - ratio) + originDeg
        let spinRad = (spinDeg - 90) * .pi / 180
                      - Double(wheel.storedHoleNumber - 1) * holeAngularStep

        let path = toothPath(center: wc, rootRadius: outerR, tipRadius: outerR + depth,
                             notchCount: count, startAngle: spinRad, clockwise: false)

        context.drawLayer { ctx in
            ctx.opacity = 0.63
            ctx.fill(path, with: .color(gearFill))
            applyGradient(to: path, center: wc, radius: outerR, context: &ctx)
            ctx.stroke(path, with: .color(gearStroke), lineWidth: 0.2)
            drawHoles(for: wheel, wheelCenter: wc, spinRad: spinRad, context: &ctx)
        }
    }

    // MARK: - Holes

    // Angular step between consecutive holes, matching the gentle inward spiral
    // seen on physical Spirograph wheels (~13° per hole looks natural).
    private let holeAngularStep: Double = 25 * .pi / 180

    private func drawHoles(for wheel: SpiroWheel, wheelCenter: CGPoint,
                            spinRad: Double, context: inout GraphicsContext) {
        let holeR   = CGFloat(3)
        // notchCount / 2 - invisibleHolesToEdge matches physical Spirograph hole counts:
        // 24→5, 36→11, 63→24, 64→25, 80→33
        let maxHole = max(1, wheel.outerNotchCircumference / 2 - SpiroCircle.invisibleHolesToEdge)

        // Mirror SpiroCircle.penRadius: hole 1 just inside the tooth root, hole maxHole near center.
        let outerR = CGFloat(wheel.outerRadius)
        let firstR = outerR - CGFloat(wheel.notchSize * 2 / .pi)
        let stepR  = firstR / CGFloat(maxHole)

        for h in 1...maxHole {
            let r = firstR - CGFloat(h - 1) * stepR
            guard r > holeR else { break }

            // Each hole steps inward in radius AND rotates slightly, forming a spiral.
            let holeAngle = spinRad + Double(h - 1) * holeAngularStep
            let hc   = CGPoint(x: wheelCenter.x + r * CGFloat(cos(holeAngle)),
                               y: wheelCenter.y + r * CGFloat(sin(holeAngle)))
            let rect = CGRect(x: hc.x - holeR, y: hc.y - holeR,
                              width: holeR * 2, height: holeR * 2)
            let holePath = Path(ellipseIn: rect)

            var hCtx = context
            hCtx.clip(to: holePath)
            hCtx.fill(Path(rect), with: .linearGradient(
                Gradient(stops: [
                    .init(color: holeGradLeft,  location: 0),
                    .init(color: holeGradRight, location: 1)
                ]),
                startPoint: CGPoint(x: rect.minX, y: hc.y),
                endPoint:   CGPoint(x: rect.maxX, y: hc.y)
            ))
            context.stroke(holePath, with: .color(holeStroke), lineWidth: 0.8)
        }
    }

    // MARK: - Gradient helper

    private func applyGradient(to path: Path, center: CGPoint, radius: CGFloat,
                                context: inout GraphicsContext) {
        var gCtx = context
        gCtx.clip(to: path)
        let rect = centeredRect(at: center, radius: radius)
        gCtx.fill(Path(rect), with: .linearGradient(
            Gradient(stops: [
                .init(color: gearGradLeft,  location: 0),
                .init(color: gearGradRight, location: 1)
            ]),
            startPoint: CGPoint(x: rect.minX, y: center.y),
            endPoint:   CGPoint(x: rect.maxX, y: center.y)
        ))
    }

    // MARK: - Path generation

    /// Cut-out path for the ring's inner hole. Teeth dip inward (rootRadius = innerRadius,
    /// tipRadius = innerRadius - toothDepth), so the ring body gains inward teeth after the cut.
    private func innerCutPath(center: CGPoint, innerRadius: CGFloat,
                               notchCount: Int, toothDepth: CGFloat) -> Path {
        toothPath(center: center, rootRadius: innerRadius,
                  tipRadius: innerRadius - toothDepth,
                  notchCount: notchCount, startAngle: -.pi / 2, clockwise: false)
    }

    /// General gear-tooth path. Alternates arcs at rootRadius (gaps) with triangular teeth.
    private func toothPath(center: CGPoint, rootRadius: CGFloat, tipRadius: CGFloat,
                            notchCount: Int, startAngle: Double, clockwise: Bool) -> Path {
        var path    = Path()
        let arc     = 2.0 * Double.pi / Double(notchCount)
        let gap     = 0.35   // fraction of arc that is gap, split half/half around each tooth
        let dir     = clockwise ? -1.0 : 1.0

        for i in 0..<notchCount {
            let base       = startAngle + dir * Double(i) * arc
            let toothStart = base + dir * arc * gap / 2
            let toothEnd   = base + dir * arc * (1 - gap / 2)
            let nextBase   = base + dir * arc

            if i == 0 { path.move(to: polar(center, rootRadius, base)) }

            path.addArc(center: center, radius: rootRadius,
                        startAngle: .radians(base),       endAngle: .radians(toothStart), clockwise: clockwise)
            let toothMid = (toothStart + toothEnd) / 2
            path.addLine(to: polar(center, tipRadius,  toothMid))   // rising flank → peak
            path.addLine(to: polar(center, rootRadius, toothEnd))   // falling flank
            path.addArc(center: center, radius: rootRadius,
                        startAngle: .radians(toothEnd),   endAngle: .radians(nextBase),   clockwise: clockwise)
        }
        path.closeSubpath()
        return path
    }

    // MARK: - Geometry helpers

    private func polar(_ c: CGPoint, _ r: CGFloat, _ a: Double) -> CGPoint {
        CGPoint(x: c.x + r * CGFloat(cos(a)), y: c.y + r * CGFloat(sin(a)))
    }

    private func centeredRect(at center: CGPoint, radius: CGFloat) -> CGRect {
        CGRect(x: center.x - radius, y: center.y - radius,
               width: radius * 2,    height: radius * 2)
    }
}
