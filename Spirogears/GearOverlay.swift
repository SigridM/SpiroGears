import SwiftUI

// MARK: - Gear overlay rendered via SwiftUI Canvas, layered above the spiral drawing.
// Draws the stationary ring and the rolling wheel for the given layer.
// wheelAngle is the wheel-center's angle around the ring center, in degrees from top (0 = top).

// MARK: - Outside-ring cursor indicator

/// Tints the area outside the ring when the cursor exits during manual drawing.
struct OutsideRingOverlayView: View {
    let layer: SpiroLayer
    var scale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geo in
            // Scale only the ring cutout, not the background fill, so the tint
            // always covers the full screen regardless of the zoom level.
            let center = CGPoint(x: geo.size.width  / 2 + layer.offset.x * scale,
                                 y: geo.size.height / 2 + layer.offset.y * scale)
            let r = CGFloat(layer.stationaryGuide.innerRadius) * scale
            Path { path in
                path.addRect(CGRect(origin: .zero, size: geo.size))
                path.addEllipse(in: CGRect(x: center.x - r, y: center.y - r,
                                           width: r * 2,    height: r * 2))
            }
            .fill(Color.orange.opacity(0.20), style: FillStyle(eoFill: true))
        }
        .allowsHitTesting(false)
    }
}

private let gearFill   = Color.white
private let gearStroke = Color(white: 0.72)           // gray edge
private let gearGlow   = Color(white: 0.40).opacity(0.35) // soft gray outer glow for depth
private let holeFill   = Color(white: 0.82)           // gray so holes read as inset
private let holeStroke = Color(white: 0.65)
private let ringBandWidth: CGFloat = 14           // visible ring thickness in points

struct GearOverlayView: View {
    let layer: SpiroLayer
    var wheelAngle: Double = 0

    var body: some View {
        // Use a GeometryReader so we know the screen size, then render the Canvas at
        // 2× that size (centered on screen).  This matches SpiroCanvas's oversized
        // image approach: content that extends beyond the screen edge is rendered
        // rather than clipped, so pinching out reveals the full ring and wheel.
        GeometryReader { geo in
            Canvas { context, size in
                // size is 2× screen.  size.width/2 == screenWidth, so the ring
                // center at (screenCenter + offset) lands at
                // (screenWidth + offset.x, screenHeight + offset.y) — exactly
                // where SpiroCanvas places it in its own 2× render image.
                let center = CGPoint(x: size.width  / 2 + layer.offset.x,
                                     y: size.height / 2 + layer.offset.y)
                drawRing(layer.stationaryGuide, center: center, context: &context)
                drawWheel(layer.penGuide, around: layer.stationaryGuide,
                          center: center, angle: wheelAngle, context: &context)
            }
            .frame(width: geo.size.width * 2, height: geo.size.height * 2)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
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

        let disk = Path(ellipseIn: centeredRect(at: center, radius: displayOuterR))
        let cut  = innerCutPath(center: center, innerRadius: innerR,
                                notchCount: count, toothDepth: depth)

        // Fill ring band with white, cut inner hole
        context.drawLayer { ctx in
            ctx.opacity = 0.88
            ctx.fill(disk, with: .color(gearFill))
            ctx.blendMode = .destinationOut
            ctx.fill(cut, with: .color(.white))
        }

        // Stroke both edges with a soft cyan-blue glow
        context.drawLayer { ctx in
            ctx.addFilter(.shadow(color: gearGlow, radius: 4, x: 0, y: 0))
            ctx.stroke(disk, with: .color(gearStroke), lineWidth: 1.5)
            ctx.stroke(cut,  with: .color(gearStroke), lineWidth: 1.5)
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
        // With outward ring notches, even-tooth wheels mesh correctly with no offset.
        // Odd-tooth wheels land half a tooth out of phase and need a -π/count correction.
        let toothPhaseOffset = count % 2 != 0 ? -Double.pi / Double(count) : 0.0
        let spinRad = (spinDeg - 90) * .pi / 180 + toothPhaseOffset
                      - Double(wheel.storedHoleNumber - 1) * holeAngularStep

        let path = toothPath(center: wc, rootRadius: outerR, tipRadius: outerR + depth,
                             notchCount: count, startAngle: spinRad, clockwise: false)

        // Fill wheel with white
        context.drawLayer { ctx in
            ctx.opacity = 0.88
            ctx.fill(path, with: .color(gearFill))
        }

        // Stroke gear outline with a soft cyan-blue glow
        context.drawLayer { ctx in
            ctx.addFilter(.shadow(color: gearGlow, radius: 4, x: 0, y: 0))
            ctx.stroke(path, with: .color(gearStroke), lineWidth: 1.5)
        }

        // Holes drawn without shadow so they read as inset depressions
        drawHoles(for: wheel, wheelCenter: wc, spinRad: spinRad,
                  selectedHole: wheel.storedHoleNumber,
                  penColor: Color(uiColor: layer.penColor), context: &context)
    }

    // MARK: - Holes

    // Angular step between consecutive holes, matching the gentle inward spiral
    // seen on physical Spirograph wheels (~13° per hole looks natural).
    private let holeAngularStep: Double = 30 * .pi / 180

    private func drawHoles(for wheel: SpiroWheel, wheelCenter: CGPoint,
                            spinRad: Double, selectedHole: Int, penColor: Color,
                            context: inout GraphicsContext) {
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
            let hc       = CGPoint(x: wheelCenter.x + r * CGFloat(cos(holeAngle)),
                                   y: wheelCenter.y + r * CGFloat(sin(holeAngle)))
            let holePath = Path(ellipseIn: CGRect(x: hc.x - holeR, y: hc.y - holeR,
                                                  width: holeR * 2, height: holeR * 2))

            // The selected hole is filled with the layer's pen color so it's identifiable.
            let fill = h == selectedHole ? penColor : holeFill
            context.fill(holePath, with: .color(fill))
            context.stroke(holePath, with: .color(holeStroke), lineWidth: 0.8)
        }
    }

    // MARK: - Path generation

    /// Cut-out path for the ring's inner hole. Notches go outward (tipRadius = innerRadius +
    /// toothDepth) so they are cut into the ring band, matching the outward wheel teeth.
    private func innerCutPath(center: CGPoint, innerRadius: CGFloat,
                               notchCount: Int, toothDepth: CGFloat) -> Path {
        toothPath(center: center, rootRadius: innerRadius,
                  tipRadius: innerRadius + toothDepth,
                  notchCount: notchCount, startAngle: -.pi / 2, clockwise: false)
    }

    /// General gear-tooth path. Alternates arcs at rootRadius (gaps) with teeth that have
    /// a small arc at the tip so peaks are blunted to match the rounded valleys.
    private func toothPath(center: CGPoint, rootRadius: CGFloat, tipRadius: CGFloat,
                            notchCount: Int, startAngle: Double, clockwise: Bool) -> Path {
        var path      = Path()
        let arc       = 2.0 * Double.pi / Double(notchCount)
        let gap       = 0.35   // fraction of arc that is gap, split half/half around each tooth
        let bluntHalf = arc * 0.08  // half-width of the blunted tip arc
        let dir       = clockwise ? -1.0 : 1.0

        for i in 0..<notchCount {
            let base       = startAngle + dir * Double(i) * arc
            let toothStart = base + dir * arc * gap / 2
            let toothEnd   = base + dir * arc * (1 - gap / 2)
            let nextBase   = base + dir * arc
            let tipStart   = (toothStart + toothEnd) / 2 - dir * bluntHalf
            let tipEnd     = (toothStart + toothEnd) / 2 + dir * bluntHalf

            if i == 0 { path.move(to: polar(center, rootRadius, base)) }

            path.addArc(center: center, radius: rootRadius,
                        startAngle: .radians(base),      endAngle: .radians(toothStart), clockwise: clockwise)
            path.addLine(to: polar(center, tipRadius, tipStart))    // rising flank
            path.addArc(center: center, radius: tipRadius,
                        startAngle: .radians(tipStart),  endAngle: .radians(tipEnd),      clockwise: clockwise)
            path.addLine(to: polar(center, rootRadius, toothEnd))   // falling flank
            path.addArc(center: center, radius: rootRadius,
                        startAngle: .radians(toothEnd),  endAngle: .radians(nextBase),    clockwise: clockwise)
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
