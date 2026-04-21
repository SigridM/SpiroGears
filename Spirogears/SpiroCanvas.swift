import Combine
import SwiftUI
import UIKit

// MARK: - Observable canvas (Option B: accumulates layers as a UIImage)
// Renders into a 2× oversized canvas so drawings that extend beyond the screen
// are fully captured. The view displays this at 0.5× by default (filling the screen)
// and lets the user pinch to zoom in or out.

@MainActor
class SpiroCanvas: ObservableObject {
    @Published private(set) var renderedImage: UIImage?
    @Published private(set) var animationOverlayImage: UIImage?
    @Published private(set) var isAnimating = false
    @Published private(set) var animationWheelAngle: Double = 0
    @Published private(set) var animatingLayer: SpiroLayer?

    @Published private(set) var isManualDrawing = false
    @Published private(set) var manualOverlayImage: UIImage?
    @Published private(set) var manualWheelAngle: Double = 0
    @Published private(set) var manualLayer: SpiroLayer?
    private var manualLastStep: Int = 0

    private var animationTask: Task<Void, Never>?
    private var pendingDrawing: SpiroDrawing?

    private var canvasSize: CGSize = .zero

    var size: CGSize { canvasSize }

    // The render canvas is 2× the screen in each dimension.
    // Drawings are translated to the center of this larger canvas.
    private let oversizeFactor: CGFloat = 2.0

    private var renderSize: CGSize {
        CGSize(width: canvasSize.width * oversizeFactor,
               height: canvasSize.height * oversizeFactor)
    }

    // Amount to shift drawing content so it stays centered in the larger canvas.
    private var renderOffset: CGPoint {
        CGPoint(x: canvasSize.width  * (oversizeFactor - 1) / 2,
                y: canvasSize.height * (oversizeFactor - 1) / 2)
    }

    func setSize(_ size: CGSize) {
        canvasSize = size
    }

    // MARK: - Animation

    // Animate a single newly-added layer.
    func animateLayer(_ layer: SpiroLayer, pointsPerFrame: Int) {
        guard canvasSize.width > 0, canvasSize.height > 0 else { appendLayer(layer); return }
        guard layer.stepCount > 0 else { appendLayer(layer); return }

        pendingDrawing  = nil
        animatingLayer  = layer
        isAnimating     = true
        animationWheelAngle    = 0
        animationOverlayImage  = nil

        animationTask = Task { @MainActor in
            await runAnimation(for: layer, pointsPerFrame: pointsPerFrame)
            guard !Task.isCancelled else { return }
            isAnimating    = false
            animatingLayer = nil
        }
    }

    // Animate all layers in a drawing sequentially (e.g., loading a preset).
    func animateDrawing(_ drawing: SpiroDrawing, pointsPerFrame: Int) {
        cancelAnimation()
        let layers = drawing.layers
        guard !layers.isEmpty, canvasSize.width > 0, canvasSize.height > 0 else {
            redrawAll(drawing: drawing)
            return
        }

        pendingDrawing  = drawing
        isAnimating     = true
        animationWheelAngle   = 0
        animationOverlayImage = nil

        animationTask = Task { @MainActor in
            for layer in layers {
                guard !Task.isCancelled else { break }
                animatingLayer = layer
                await runAnimation(for: layer, pointsPerFrame: pointsPerFrame)
            }
            guard !Task.isCancelled else { return }
            isAnimating    = false
            animatingLayer = nil
            pendingDrawing = nil
        }
    }

    // Core per-layer animation loop; can be awaited so layers chain sequentially.
    private func runAnimation(for layer: SpiroLayer, pointsPerFrame: Int) async {
        let steps  = layer.stepCount
        let rect   = CGRect(origin: .zero, size: canvasSize)
        let offset = renderOffset
        let size   = renderSize
        let color  = layer.penColor.cgColor

        var overlayImage: UIImage? = nil
        var i = 0

        while i < steps {
            guard !Task.isCancelled else { return }

            let batchEnd = min(i + pointsPerFrame, steps)

            overlayImage = UIGraphicsImageRenderer(size: size).image { ctx in
                overlayImage?.draw(at: .zero)
                ctx.cgContext.saveGState()
                ctx.cgContext.translateBy(x: offset.x, y: offset.y)
                ctx.cgContext.setStrokeColor(color)
                ctx.cgContext.setLineWidth(1.0)
                ctx.cgContext.move(to: layer.point(at: i, in: rect))
                for j in (i + 1)...batchEnd {
                    ctx.cgContext.addLine(to: layer.point(at: j, in: rect))
                }
                ctx.cgContext.strokePath()
                ctx.cgContext.restoreGState()
            }

            animationOverlayImage  = overlayImage
            animationWheelAngle    = layer.stationaryGuide.angleIncrement * Double(batchEnd)
            i = batchEnd
            await Task.yield()
        }

        guard !Task.isCancelled else { return }
        // Merge this layer's overlay into the persistent canvas image.
        let finalOverlay = overlayImage
        renderedImage = UIGraphicsImageRenderer(size: size).image { ctx in
            renderedImage?.draw(at: .zero)
            finalOverlay?.draw(at: .zero)
        }
        animationOverlayImage = nil
        animationWheelAngle   = 0
    }

    // Complete the in-progress animation immediately (tap-to-skip).
    func skipAnimation() {
        guard isAnimating else { return }
        let capturedOverlay = animationOverlayImage
        let capturedLayer   = animatingLayer
        let capturedDrawing = pendingDrawing

        animationTask?.cancel()
        animationTask         = nil
        animationOverlayImage = nil
        isAnimating           = false
        animationWheelAngle   = 0
        animatingLayer        = nil
        pendingDrawing        = nil

        let rect   = CGRect(origin: .zero, size: canvasSize)
        let offset = renderOffset
        let size   = renderSize

        if let drawing = capturedDrawing {
            // Redraw all layers in the drawing from scratch.
            renderedImage = UIGraphicsImageRenderer(size: size).image { ctx in
                ctx.cgContext.saveGState()
                ctx.cgContext.translateBy(x: offset.x, y: offset.y)
                drawing.draw(in: ctx.cgContext, rect: rect)
                ctx.cgContext.restoreGState()
            }
        } else if let layer = capturedLayer {
            // Complete the single in-progress layer.
            renderedImage = UIGraphicsImageRenderer(size: size).image { ctx in
                renderedImage?.draw(at: .zero)
                capturedOverlay?.draw(at: .zero)
                ctx.cgContext.saveGState()
                ctx.cgContext.translateBy(x: offset.x, y: offset.y)
                let path = layer.path(in: rect)
                ctx.cgContext.setStrokeColor(layer.penColor.cgColor)
                ctx.cgContext.setLineWidth(1.0)
                ctx.cgContext.addPath(path.cgPath)
                ctx.cgContext.strokePath()
                ctx.cgContext.restoreGState()
            }
        }
    }

    // Cancel and discard any in-progress animation (e.g., on clear / undo).
    func cancelAnimation() {
        guard isAnimating else { return }
        animationTask?.cancel()
        animationTask         = nil
        animationOverlayImage = nil
        isAnimating           = false
        animationWheelAngle   = 0
        animatingLayer        = nil
        pendingDrawing        = nil
    }

    // MARK: - Manual Drawing

    func beginManualDrawing(layer: SpiroLayer) {
        cancelAnimation()
        manualLayer        = layer
        manualLastStep     = 0
        manualWheelAngle   = 0
        manualOverlayImage = nil
        isManualDrawing    = true
    }

    // Stroke from the last committed step up to `step`, updating the overlay image.
    // step may be positive (CW) or negative (CCW); the direction is determined by
    // whichever way the caller moves step away from zero.
    func updateManualDrawing(toStep step: Int) {
        guard isManualDrawing, let layer = manualLayer, step != manualLastStep else { return }
        guard canvasSize.width > 0 else { return }

        let rect   = CGRect(origin: .zero, size: canvasSize)
        let offset = renderOffset
        let size   = renderSize
        let color  = layer.penColor.cgColor

        manualOverlayImage = UIGraphicsImageRenderer(size: size).image { ctx in
            manualOverlayImage?.draw(at: .zero)
            ctx.cgContext.saveGState()
            ctx.cgContext.translateBy(x: offset.x, y: offset.y)
            ctx.cgContext.setStrokeColor(color)
            ctx.cgContext.setLineWidth(1.0)
            ctx.cgContext.move(to: layer.point(at: manualLastStep, in: rect))
            if step > manualLastStep {
                for j in (manualLastStep + 1)...step {
                    ctx.cgContext.addLine(to: layer.point(at: j, in: rect))
                }
            } else {
                for j in stride(from: manualLastStep - 1, through: step, by: -1) {
                    ctx.cgContext.addLine(to: layer.point(at: j, in: rect))
                }
            }
            ctx.cgContext.strokePath()
            ctx.cgContext.restoreGState()
        }

        manualLastStep   = step
        manualWheelAngle = layer.stationaryGuide.angleIncrement * Double(step)
    }

    // Merge the manual overlay into the persistent canvas. Returns the layer if any
    // strokes were drawn, nil if the user lifted without dragging.
    func endManualDrawing() -> SpiroLayer? {
        // Use manualOverlayImage as the "strokes were drawn" signal — jumpManualStep
        // can set manualLastStep != 0 before any strokes, so that's no longer reliable.
        let drawnLayer = manualOverlayImage != nil ? manualLayer : nil
        if let overlay = manualOverlayImage, drawnLayer != nil {
            let size = renderSize
            renderedImage = UIGraphicsImageRenderer(size: size).image { ctx in
                renderedImage?.draw(at: .zero)
                overlay.draw(at: .zero)
            }
        }
        isManualDrawing    = false
        manualOverlayImage = nil
        manualWheelAngle   = 0
        manualLayer        = nil
        manualLastStep     = 0
        return drawnLayer
    }

    func cancelManualDrawing() {
        guard isManualDrawing else { return }
        isManualDrawing    = false
        manualOverlayImage = nil
        manualWheelAngle   = 0
        manualLayer        = nil
        manualLastStep     = 0
    }

    // MARK: - Rendering

    func appendLayer(_ layer: SpiroLayer) {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return }
        let rect   = CGRect(origin: .zero, size: canvasSize)
        let offset = renderOffset
        renderedImage = UIGraphicsImageRenderer(size: renderSize).image { ctx in
            self.renderedImage?.draw(at: .zero)
            ctx.cgContext.saveGState()
            ctx.cgContext.translateBy(x: offset.x, y: offset.y)
            let path = layer.path(in: rect)
            ctx.cgContext.setStrokeColor(layer.penColor.cgColor)
            ctx.cgContext.setLineWidth(1.0)
            ctx.cgContext.addPath(path.cgPath)
            ctx.cgContext.strokePath()
            ctx.cgContext.restoreGState()
        }
    }

    func redrawAll(drawing: SpiroDrawing) {
        cancelAnimation()
        cancelManualDrawing()
        guard canvasSize.width > 0, canvasSize.height > 0 else { return }
        let rect   = CGRect(origin: .zero, size: canvasSize)
        let offset = renderOffset
        renderedImage = UIGraphicsImageRenderer(size: renderSize).image { ctx in
            ctx.cgContext.saveGState()
            ctx.cgContext.translateBy(x: offset.x, y: offset.y)
            drawing.draw(in: ctx.cgContext, rect: rect)
            ctx.cgContext.restoreGState()
        }
    }

    func clear() {
        cancelAnimation()
        cancelManualDrawing()
        renderedImage = nil
    }
}

// MARK: - Canvas view with pinch-to-zoom

struct SpiroCanvasView: View {
    @ObservedObject var canvas: SpiroCanvas
    @Binding var scale: CGFloat
    @Binding var lastScale: CGFloat

    var body: some View {
        Color.white
            .overlay(
                Group {
                    if let image = canvas.renderedImage {
                        // The image is 2× screen size. At scale=1 its centre aligns with the
                        // screen centre and the visible region looks identical to the old
                        // single-screen render. Pinching in zooms; pinching out shrinks the
                        // image and reveals drawing content that was beyond the screen edge.
                        // allowsHitTesting(false): the oversized layout footprint would
                        // otherwise absorb gestures before they reached the recognisers below.
                        Image(uiImage: image)
                            .scaleEffect(scale)
                            .allowsHitTesting(false)
                    }
                    if let animImage = canvas.animationOverlayImage {
                        Image(uiImage: animImage)
                            .scaleEffect(scale)
                            .allowsHitTesting(false)
                    }
                    if let manualImage = canvas.manualOverlayImage {
                        Image(uiImage: manualImage)
                            .scaleEffect(scale)
                            .allowsHitTesting(false)
                    }
                }
            )
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { canvas.setSize(geo.size) }
                        .onChange(of: geo.size) { _, newSize in canvas.setSize(newSize) }
                }
            )
            .contentShape(Rectangle())
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = max(0.25, lastScale * value)
                    }
                    .onEnded { value in
                        lastScale = max(0.25, lastScale * value)
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring()) {
                    scale = 1.0
                    lastScale = 1.0
                }
            }
    }
}
