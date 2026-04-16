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
    private var canvasSize: CGSize = .zero

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
        renderedImage = nil
    }
}

// MARK: - Canvas view with pinch-to-zoom

struct SpiroCanvasView: View {
    @ObservedObject var canvas: SpiroCanvas

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

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
