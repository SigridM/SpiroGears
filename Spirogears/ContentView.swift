//
//  ContentView.swift
//  Spirogears
//
//  Created by Sigrid Mortensen on 4/16/26.
//

import SwiftUI

// Equivalent to SpiroDrawingWorkspace.
// Owns the canvas, current drawing, and undo stack.

struct ContentView: View {
    @StateObject private var canvas = SpiroCanvas()
    @State private var currentDrawing: SpiroDrawing?
    @State private var currentDrawingName: String = ""
    @State private var undoOps: [LayerOp] = []
    @State private var redoOps: [LayerOp] = []
    @State private var isModified = false
    @State private var layerVersion = 0

    @AppStorage("showGears")              private var showGears             = true
    @AppStorage("animate")                private var animate               = false
    @AppStorage("animationSpeed")         private var animationSpeed        = AnimationSpeed.medium
    @AppStorage("manualDrawing")          private var manualDrawing         = false
    @AppStorage("haptics")                private var haptics               = true
    @AppStorage("defaultBackgroundColor") private var defaultBackgroundColorHex: String = "#FFFFFF"

    private var defaultBackgroundUIColor: UIColor {
        UIColor(hex: defaultBackgroundColorHex) ?? .white
    }

    // Zoom state lifted from SpiroCanvasView so GearOverlayView can share the same scale
    @State private var canvasScale: CGFloat = 1.0
    @State private var canvasLastScale: CGFloat = 1.0

    // Manual drawing gesture state
    @State private var manualPrevTranslation: CGSize    = .zero
    @State private var manualAccumulatedNotches: Double = 0
    @State private var manualDirection: Int             = 0  // +1 CW, -1 CCW, 0 not yet set
    @State private var manualJumpStep: Int              = 0  // absolute step at which drawing started
    // Size of the drag-capture view (same coordinate system as GearOverlayView).
    // canvas.size may differ because its GeometryReader is inside a view that has
    // .ignoresSafeArea() applied externally, which can give a different height.
    @State private var dragViewSize: CGSize             = .zero
    // True only while a finger/stylus is actively on the screen during manual drawing.
    // Gears are always shown during an active drag; the toggle controls them otherwise.
    @State private var manualDragActive: Bool           = false
    // True while the cursor is outside the ring during a manual drag.
    @State private var manualCursorOutside: Bool        = false

    @Environment(SubscriptionStore.self) private var store
    @AppStorage("drawingsCreated") private var drawingsCreated = 0

    @State private var shareImage: UIImage?
    @State private var shareURL: URL?
    @State private var showingConfig = false
    @State private var showingSettings = false
    @State private var showingSaveAlert = false
    @State private var showingSaveBeforeAction = false
    @State private var showingPresetNameError = false
    @State private var paywallRequest: PaywallRequest? = nil
    @State private var layersSheetContext: LayersSheetContext? = nil

    @State private var saveNameInput = ""
    @State private var savedDrawingNames: [String] = []
    @State private var savedThumbnails: [String: UIImage] = [:]
    @State private var pendingAction: DrawingMenuView.Action? = nil

    var body: some View {
        ZStack(alignment: .top) {
            SpiroCanvasView(canvas: canvas, scale: $canvasScale, lastScale: $canvasLastScale)
                .ignoresSafeArea()

            // During an active manual drag the gears always show so the user can
            // see where the wheel is; otherwise the Gears toggle governs visibility.
            if showGears || manualDragActive {
                let overlayLayer = canvas.animatingLayer
                                ?? (canvas.isManualDrawing ? canvas.manualLayer : nil)
                                ?? currentDrawing?.layers.last
                let overlayAngle = canvas.isAnimating
                                 ? canvas.animationWheelAngle
                                 : canvas.manualWheelAngle
                if let layer = overlayLayer {
                    GearOverlayView(layer: layer, wheelAngle: overlayAngle)
                        .scaleEffect(canvasScale)
                        .ignoresSafeArea()
                }
            }

            // Outside-ring indicator: fades in when the cursor exits the ring.
            if manualCursorOutside, let layer = canvas.manualLayer {
                OutsideRingOverlayView(layer: layer, scale: canvasScale)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            // Manual drawing drag capture — below the controls so the controls
            // remain tappable. On a real device a recognised DragGesture keeps the
            // touch even when the finger moves over the button area.
            if canvas.isManualDrawing {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear { dragViewSize = geo.size }
                                .onChange(of: geo.size) { _, s in dragViewSize = s }
                        }
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                manualDragActive = true
                                handleManualDrag(value)
                            }
                            .onEnded { _ in
                                manualPrevTranslation = .zero
                                // Re-lock direction on next touch so catch-up fires — UNLESS
                                // the drawing has reached endStep. In that case, preserve the
                                // direction so a re-touch followed by backward dragging is
                                // treated as "back up to erase" rather than triggering a new
                                // CCW catch-up that draws backward in step space.
                                let atEnd = canvas.manualLayer.map {
                                    abs(canvas.manualLastStep) >= $0.effectiveEndStep
                                } ?? false
                                if !atEnd { manualDirection = 0 }
                                manualDragActive      = false
                                withAnimation(.easeOut(duration: 0.2)) { manualCursorOutside = false }
                            }
                    )
                    // Allow pinch-to-zoom while a manual draw is in progress.
                    .simultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                canvasScale = max(0.25, canvasLastScale * value)
                            }
                            .onEnded { value in
                                canvasLastScale = max(0.25, canvasLastScale * value)
                            }
                    )
            }

            // Top controls bar
            HStack(alignment: .center) {
                // Share button — left side
                if let url = shareURL, let image = shareImage {
                    ShareLink(item: url, preview: SharePreview("Spirogears Drawing", image: Image(uiImage: image))) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                }

                Spacer()

                // Right-side controls
                Toggle("Gears", isOn: $showGears)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .fixedSize()

                if canvas.isAnimating {
                    Button("Finish Now") { canvas.skipAnimation() }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.regularMaterial, in: Capsule())
                }

                Button {
                    if canvas.isManualDrawing { finalizeManualDrawing() }
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: Capsule())
            }
            .padding(.top, 60)
            .padding(.horizontal, 16)

            // Bottom drawing palette
            VStack {
                Spacer()
                DrawingPaletteView(
                    currentDrawing: currentDrawing,
                    savedDrawingNames: savedDrawingNames,
                    thumbnails: savedThumbnails,
                    hasUndo: !undoOps.isEmpty,
                    hasUndone: !redoOps.isEmpty,
                    onAction: { action in handleMenuAction(action) },
                    onShowLayers: {
                        if let d = currentDrawing {
                            layersSheetContext = LayersSheetContext(drawing: d)
                        }
                    }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack { SettingsView() }
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingConfig) {
            SpiroConfigView(data: SpiroDialogData.lastData) { data in
                showingConfig = false
                guard let data else { return }
                if currentDrawing == nil { currentDrawing = SpiroDrawing() }
                let layer = data.makeLayer()
                redoOps.removeAll()
                if manualDrawing {
                    // Gears must be visible while drawing manually.
                    showGears = true
                    // Don't commit to the drawing yet — wait for the drag to finish.
                    canvas.beginManualDrawing(layer: layer)
                    isModified = true
                    // undoOps updated in finalizeManualDrawing; share image updated via onChange(isManualDrawing)
                } else if animate {
                    currentDrawing?.addLayer(layer)
                    undoOps.append(.added(layer))
                    canvas.animateLayer(layer, pointsPerFrame: animationSpeed.pointsPerFrame)
                    isModified = true
                    // share image updated via onChange(isAnimating)
                } else {
                    currentDrawing?.addLayer(layer)
                    undoOps.append(.added(layer))
                    canvas.appendLayer(layer)
                    isModified = true
                    updateShareImage()
                }
            }
        }
        .sheet(item: $paywallRequest) { request in
            PaywallView(feature: request.feature) { paywallRequest = nil }
                .environment(store)
        }
        .sheet(item: $layersSheetContext) { ctx in
            NavigationStack {
                LayersView(
                    drawing: ctx.drawing,
                    layerVersion: layerVersion,
                    isSubscribed: store.entitlement != .free,
                    onAction: { action in handleMenuAction(action) }
                )
            }
            .environment(store)
            .presentationDetents([.medium, .large])
        }

        .task {
            savedDrawingNames = SpiroDrawing.savedDrawingNames
            canvas.hapticsEnabled = haptics
            // Generate preset thumbnails on a background thread (rendering can be slow for complex drawings).
            let thumbs = await Task.detached(priority: .userInitiated) {
                SpiroDrawing.allThumbnails
            }.value
            savedThumbnails = thumbs
        }
        .onChange(of: haptics) { _, value in canvas.hapticsEnabled = value }
        .onChange(of: canvas.isAnimating) { _, animating in if !animating { updateShareImage() } }
        .onChange(of: canvas.isManualDrawing) { _, drawing in if !drawing { updateShareImage() } }
        .alert("Save Drawing", isPresented: $showingSaveAlert) {
            TextField("Name", text: $saveNameInput)
            Button("Save") { confirmSave() }
            Button("Cancel", role: .cancel) { pendingAction = nil }
        }
        .alert("Save Current Drawing?", isPresented: $showingSaveBeforeAction) {
            Button("Save") {
                saveNameInput = currentDrawingName
                showingSaveAlert = true
            }
            Button("Discard", role: .destructive) {
                runPendingAction()
            }
            Button("Cancel", role: .cancel) {
                pendingAction = nil
            }
        } message: {
            Text("You have unsaved changes.")
        }
        .alert("Reserved Name", isPresented: $showingPresetNameError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\"\(saveNameInput)\" is a preset name and cannot be overwritten.")
        }
    }

    // MARK: - Menu action handler

    private func handleMenuAction(_ action: DrawingMenuView.Action) {
        if canvas.isManualDrawing { finalizeManualDrawing() }

        if shouldPromptToSave(before: action) {
            pendingAction = action
            showingSaveBeforeAction = true
            return
        }

        performAction(action)
    }

    private func shouldPromptToSave(before action: DrawingMenuView.Action) -> Bool {
        guard let drawing = currentDrawing, !drawing.layers.isEmpty, isModified else { return false }
        switch action {
        case .drawExample, .drawNew, .drawSaved, .useAsTemplate, .useLayersAsTemplate, .clear:
            return true
        default:
            return false
        }
    }

    private func performAction(_ action: DrawingMenuView.Action) {
        switch action {
        case .drawExample(let n):
            switch n {
            case 1: loadDrawing(.example())
            case 4: loadDrawing(.example4())
            case 5: loadDrawing(.example5())
            default: break
            }
        case .drawNew:
            if store.entitlement == .free && drawingsCreated >= SubscriptionStore.freeTierDrawingLimit {
                paywallRequest = PaywallRequest(feature: "More than \(SubscriptionStore.freeTierDrawingLimit) drawings")
                return
            }
            drawingsCreated += 1
            clear()
            let newDrawing = SpiroDrawing()
            newDrawing.backgroundColor = defaultBackgroundUIColor
            currentDrawing = newDrawing
            canvas.drawingBackgroundColor = defaultBackgroundUIColor
            showConfigAfterDismiss()
        case .addLayer:
            if store.entitlement == .free,
               let drawing = currentDrawing,
               drawing.layers.count >= SubscriptionStore.freeTierLayerLimit {
                paywallRequest = PaywallRequest(feature: "More than \(SubscriptionStore.freeTierLayerLimit) layers per drawing")
                return
            }
            showConfigAfterDismiss()
        case .useAsTemplate(let data):
            if store.entitlement == .free && drawingsCreated >= SubscriptionStore.freeTierDrawingLimit {
                paywallRequest = PaywallRequest(feature: "More than \(SubscriptionStore.freeTierDrawingLimit) drawings")
                return
            }
            drawingsCreated += 1
            clear()
            let newDrawing = SpiroDrawing()
            newDrawing.backgroundColor = defaultBackgroundUIColor
            currentDrawing = newDrawing
            canvas.drawingBackgroundColor = defaultBackgroundUIColor
            SpiroDialogData.lastData = data
            showConfigAfterDismiss()
        case .useLayersAsTemplate(let dataArray):
            if store.entitlement == .free && drawingsCreated >= SubscriptionStore.freeTierDrawingLimit {
                paywallRequest = PaywallRequest(feature: "More than \(SubscriptionStore.freeTierDrawingLimit) drawings")
                return
            }
            drawingsCreated += 1
            clear()
            let newDrawing = SpiroDrawing()
            newDrawing.backgroundColor = defaultBackgroundUIColor
            for data in dataArray {
                let layer = data.makeLayer()
                newDrawing.addLayer(layer)
                undoOps.append(.added(layer))
            }
            if let last = dataArray.last {
                SpiroDialogData.lastData = last
            }
            currentDrawing = newDrawing
            layersSheetContext = nil
            canvas.drawingBackgroundColor = defaultBackgroundUIColor
            canvas.redrawAll(drawing: newDrawing)
            isModified = true
            updateShareImage()
        case .undoLayer:   undoLastLayer()
        case .redoLayer:   redoLastLayer()
        case .save:        saveDrawing()
        case .drawSaved(let name): loadSavedDrawing(named: name)
        case .deleteSaved(let name):
            SpiroDrawing.delete(name: name)
            savedDrawingNames = SpiroDrawing.savedDrawingNames
            savedThumbnails = SpiroDrawing.allThumbnails
        case .clear:       clear()

        case .deleteLayer(let index):
            guard let drawing = currentDrawing,
                  let layer = drawing.removeLayer(at: index) else { return }
            undoOps.append(.deleted(layer, at: index))
            redoOps.removeAll()
            isModified = true
            layerVersion += 1
            canvas.redrawAll(drawing: drawing)
            updateShareImage()

        case .toggleLayerHidden(let index):
            guard let drawing = currentDrawing,
                  index >= 0, index < drawing.layers.count else { return }
            drawing.layers[index].isHidden.toggle()
            isModified = true
            layerVersion += 1
            canvas.redrawAll(drawing: drawing)
            updateShareImage()

        case .moveLayer(let source, let destination):
            guard let drawing = currentDrawing else { return }
            drawing.moveLayer(from: source, to: destination)
            isModified = true
            layerVersion += 1
            canvas.redrawAll(drawing: drawing)
            updateShareImage()

        case .reconfigureLayer:
            break  // handled locally inside LayersView

        case .replaceLayer(let index, let layer):
            replaceLayer(at: index, with: layer)

        case .updateBackgroundColor(let color):
            guard let drawing = currentDrawing else { return }
            drawing.backgroundColor = color
            canvas.drawingBackgroundColor = color
            isModified = true
            layerVersion += 1
            canvas.redrawAll(drawing: drawing)
            updateShareImage()
        }
    }

    private func runPendingAction() {
        guard let action = pendingAction else { return }
        pendingAction = nil
        performAction(action)
    }

    private func showConfigAfterDismiss() {
        showingConfig = true
    }

    // MARK: - Actions

    private func loadDrawing(_ drawing: SpiroDrawing) {
        clear()
        currentDrawing = drawing
        canvas.drawingBackgroundColor = drawing.backgroundColor
        if animate {
            canvas.animateDrawing(drawing, pointsPerFrame: animationSpeed.pointsPerFrame)
            // share image updated via onChange(isAnimating)
        } else {
            canvas.redrawAll(drawing: drawing)
            updateShareImage()
        }
        // isModified stays false — just loaded, nothing changed yet
    }

    private func loadSavedDrawing(named name: String) {
        guard let drawing = SpiroDrawing.savedDrawing(named: name) else { return }
        loadDrawing(drawing)
        currentDrawingName = name
    }

    private func clear() {
        manualPrevTranslation    = .zero
        manualAccumulatedNotches = 0
        manualDirection          = 0
        manualJumpStep           = 0
        manualDragActive         = false
        manualCursorOutside      = false
        currentDrawing = nil
        currentDrawingName = ""
        undoOps.removeAll()
        redoOps.removeAll()
        layerVersion = 0
        isModified = false
        shareImage = nil
        shareURL = nil
        canvas.clear()
    }

    private func undoLastLayer() {
        guard let drawing = currentDrawing,
              let op = undoOps.popLast() else { return }
        switch op {
        case .added(let layer):
            drawing.removeLastLayer()
            redoOps.append(.added(layer))
        case .deleted(let layer, let at):
            drawing.insertLayer(layer, at: at)
            redoOps.append(.deleted(layer, at: at))
        }
        isModified = true
        layerVersion += 1
        canvas.redrawAll(drawing: drawing)
        updateShareImage()
    }

    private func redoLastLayer() {
        guard let drawing = currentDrawing,
              let op = redoOps.popLast() else { return }
        switch op {
        case .added(let layer):
            drawing.addLayer(layer)
            undoOps.append(.added(layer))
            canvas.appendLayer(layer)
        case .deleted(let layer, let at):
            drawing.removeLayer(at: at)
            undoOps.append(.deleted(layer, at: at))
            canvas.redrawAll(drawing: drawing)
        }
        isModified = true
        layerVersion += 1
        updateShareImage()
    }

    private func saveDrawing() {
        guard currentDrawing != nil else { return }
        if store.entitlement == .free && savedDrawingNames.count >= SubscriptionStore.freeTierSaveLimit {
            paywallRequest = PaywallRequest(feature: "More than \(SubscriptionStore.freeTierSaveLimit) saved drawings")
            return
        }
        saveNameInput = currentDrawingName
        showingSaveAlert = true
    }

    private func confirmSave() {
        guard let drawing = currentDrawing, !saveNameInput.isEmpty else { return }
        guard !SpiroDrawing.presetNames.contains(saveNameInput) else {
            showingPresetNameError = true
            return
        }
        SpiroDrawing.save(drawing, name: saveNameInput)
        let thumb = SpiroDrawing.generateThumbnail(for: drawing)
        SpiroDrawing.saveThumbnail(thumb, name: saveNameInput)
        currentDrawingName = saveNameInput
        savedDrawingNames = SpiroDrawing.savedDrawingNames
        savedThumbnails = SpiroDrawing.allThumbnails
        isModified = false
        runPendingAction()
    }

    private func replaceLayer(at index: Int, with newLayer: SpiroLayer) {
        guard let drawing = currentDrawing,
              index >= 0, index < drawing.layers.count else { return }
        drawing.layers[index] = newLayer
        redoOps.removeAll()
        isModified = true
        layerVersion += 1
        canvas.redrawAll(drawing: drawing)
        updateShareImage()
    }

    private func updateShareImage() {
        guard let drawing = currentDrawing, !drawing.layers.isEmpty,
              let image = canvas.exportImage(for: drawing) ?? canvas.renderedImage else {
            shareImage = nil
            shareURL = nil
            return
        }
        shareImage = image
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Spirogears Drawing.png")
        if let data = image.pngData(), (try? data.write(to: url)) != nil {
            shareURL = url
        } else {
            shareURL = nil
        }
    }

    // MARK: - Manual Drawing

    private func handleManualDrag(_ value: DragGesture.Value) {
        guard let layer = canvas.manualLayer else { return }
        let ring = layer.stationaryGuide
        // Use the drag view's own measured size so the ring center is computed in the
        // same coordinate system as GearOverlayView (both have .ignoresSafeArea()
        // applied directly). canvas.size may differ because it is set by a GeometryReader
        // inside SpiroCanvasView, whose .ignoresSafeArea() is applied externally.
        let cs = dragViewSize.width > 0 ? dragViewSize : canvas.size

        // Ring center in view coordinates (matches GearOverlayView geometry).
        let ringCenter = CGPoint(x: cs.width  / 2 + layer.offset.x,
                                 y: cs.height / 2 + layer.offset.y)

        // Reconstruct the previous location from accumulated translation.
        let prev = CGPoint(x: value.startLocation.x + manualPrevTranslation.width,
                           y: value.startLocation.y + manualPrevTranslation.height)
        let curr = value.location

        // Vectors from ring center to previous and current touch positions.
        let va = CGPoint(x: prev.x - ringCenter.x, y: prev.y - ringCenter.y)
        let vb = CGPoint(x: curr.x - ringCenter.x, y: curr.y - ringCenter.y)

        // Skip degenerate vectors (finger right on center, or no movement).
        guard hypot(Double(va.x), Double(va.y)) > 1,
              hypot(Double(vb.x), Double(vb.y)) > 1 else {
            manualPrevTranslation = value.translation
            return
        }

        // Signed angle from va to vb (positive = CW in screen coordinates).
        let cross = Double(va.x * vb.y - va.y * vb.x)
        let dot   = Double(va.x * vb.x + va.y * vb.y)
        let deltaAngle = atan2(cross, dot)  // radians

        let endStep    = layer.effectiveEndStep

        // Lock in direction from the first significant movement.
        // This runs even when the cursor is outside the ring so the direction
        // is captured regardless of where the user starts their drag.
        if manualDirection == 0 && abs(deltaAngle) > 0.01 {
            manualDirection = deltaAngle > 0 ? 1 : -1

            // Snap the wheel to the cursor's current angular position.
            // Cursor angle relative to ring center → convert to a fractional step.
            let cursorRad = atan2(Double(curr.y - ringCenter.y), Double(curr.x - ringCenter.x))
            // thetaDeg(step) = angleIncrement*step + originalAngle - 90
            // Invert: step = (cursorDeg - originalAngle + 90) / angleIncrement
            let cursorDeg = cursorRad * 180 / .pi
            let angleInc  = ring.angleIncrement          // degrees per step
            let startFrac = (cursorDeg - ring.originalAngle + 90) / angleInc
            let stepCount = layer.stepCount
            let ringN     = ring.innerNotchCircumference

            let jumpStep: Int
            let lastStep = canvas.manualLastStep
            if lastStep != 0 {
                // Resume mid-draw: advance from the last drawn step to the cursor's
                // current ring position, drawing the catch-up segment between them.
                // Uses the same forward-delta formula as ring re-entry so the pen
                // always advances in the drag direction by the shortest arc, never
                // jumping backward unexpectedly.
                let cursorRingPos = Int(((startFrac.truncatingRemainder(dividingBy: Double(ringN)))
                                         + Double(ringN))
                                        .truncatingRemainder(dividingBy: Double(ringN)))
                let lastRingPos   = ((lastStep % ringN) + ringN) % ringN
                let forwardDelta  = ((cursorRingPos - lastRingPos) * manualDirection + ringN) % ringN
                jumpStep = lastStep + manualDirection * forwardDelta
            } else {
                // First touch: snap wheel to cursor if it is within 180° of the starting
                // notch in the drawing direction. Beyond 180° the catch-up would draw
                // nearly a full cycle before the user moves, so stay at 0 instead.
                //
                // fwdNotches is the CW distance (in ring-notch units) from the starting
                // notch to the cursor. The drawing-direction distance is therefore:
                //   CW:  fwdNotches              (cursor is ahead in CW direction)
                //   CCW: ringN - fwdNotches       (cursor is ahead in CCW direction)
                let fwdNotches = ((startFrac.truncatingRemainder(dividingBy: Double(stepCount)))
                                  + Double(stepCount))
                                 .truncatingRemainder(dividingBy: Double(stepCount))
                let fwdInt = Int(fwdNotches)
                let catchUpDist = manualDirection > 0 ? fwdInt : ringN - fwdInt
                if catchUpDist <= ringN / 2 {
                    // For CW:  jumpStep = +fwdNotches (step advances positively)
                    // For CCW: jumpStep = -(endStep - fwdNotches), which places the wheel
                    //          at the cursor position and lets the CCW draw cover the
                    //          configured loop count before finalizing.
                    if manualDirection > 0 {
                        jumpStep = fwdInt
                    } else {
                        jumpStep = -(endStep - fwdInt)
                    }
                } else {
                    jumpStep = 0  // Too far away in drawing direction — start from notch 0.
                }
            }
            // Clamp so re-touching at/past the completion point doesn't produce a
            // jumpStep beyond endStep, which would make notchCap negative and require
            // extra backward drag before erasing begins.
            let clampedJump          = max(-endStep, min(jumpStep, endStep))
            manualJumpStep           = clampedJump
            manualAccumulatedNotches = 0
            canvas.jumpManualStep(to: clampedJump)
        }
        guard manualDirection != 0 else {
            manualPrevTranslation = value.translation
            return
        }
        let curRadius  = hypot(Double(vb.x), Double(vb.y))
        let prevRadius = hypot(Double(va.x), Double(va.y))
        let ringEdge   = Double(ring.innerRadius) + 30

        let isOutside = curRadius > ringEdge
        if isOutside != manualCursorOutside {
            withAnimation(.easeInOut(duration: 0.15)) { manualCursorOutside = isOutside }
        }

        if curRadius > ringEdge {
            // Outside the ring: keep the accumulator and wheel in sync with the
            // cursor but skip drawing updates entirely. This prevents incidental
            // CCW jitter outside the ring from triggering the backingUp erase.
            let deltaNotches = deltaAngle * Double(ring.innerNotchCircumference) / (2 * .pi)
                             * Double(manualDirection)
            let notchCap = Double(endStep) - Double(manualDirection * manualJumpStep)
            manualAccumulatedNotches = min(manualAccumulatedNotches + deltaNotches, notchCap)
            canvas.updateManualWheelOnly(toStep: manualJumpStep + manualDirection * Int(manualAccumulatedNotches))
            manualPrevTranslation = value.translation
            return
        }

        if prevRadius > ringEdge {
            // Re-entry: cursor just crossed back inside the ring.
            // Compute the cursor's current position in ring-notch space
            // (0 ..< ring.innerNotchCircumference). This is the only information
            // the cursor's angular position can supply — not which revolution.
            let reRad  = atan2(Double(vb.y), Double(vb.x))
            let reDeg  = reRad * 180 / .pi
            let reFrac = (reDeg - ring.originalAngle + 90) / ring.angleIncrement
            let ringN  = ring.innerNotchCircumference
            let reFwd  = Int(((reFrac.truncatingRemainder(dividingBy: Double(ringN)))
                              + Double(ringN))
                             .truncatingRemainder(dividingBy: Double(ringN)))
            // Always advance in the drawing direction from the last-drawn ring
            // position to the cursor's ring position. Never retreat — if the cursor
            // comes back slightly behind the exit point, forwardDelta is nearly
            // ringN (one full ring sweep forward) rather than a tiny retreat.
            let lastRingPos  = ((canvas.manualLastStep % ringN) + ringN) % ringN
            let forwardDelta = ((reFwd - lastRingPos) * manualDirection + ringN) % ringN
            let reStep       = canvas.manualLastStep + manualDirection * forwardDelta
            // Snap the accumulator so inside-ring drawing continues without jitter.
            // Cap at notchCap so re-entry can't advance past the end of the drawing.
            let notchCap = Double(endStep) - Double(manualDirection * manualJumpStep)
            manualAccumulatedNotches = min(Double(manualDirection * (reStep - manualJumpStep)),
                                           notchCap)
            canvas.resumeManualDrawing(atStep: reStep)
            manualPrevTranslation = value.translation
            return
        }

        // Normal inside-ring drawing.
        let deltaNotches = deltaAngle * Double(ring.innerNotchCircumference) / (2 * .pi)
                         * Double(manualDirection)
        // Cap so the step doesn't advance past endStep. The correct ceiling for the
        // accumulator is (endStep - direction*jumpStep), because
        //   step = jumpStep + direction*accumulated = endStep
        // when accumulated = endStep - direction*jumpStep. Backward motion is unrestricted.
        let notchCap = Double(endStep) - Double(manualDirection * manualJumpStep)
        manualAccumulatedNotches = min(manualAccumulatedNotches + deltaNotches, notchCap)
        let step = manualJumpStep + manualDirection * Int(manualAccumulatedNotches)
        canvas.updateManualDrawing(toStep: step)
        manualPrevTranslation = value.translation
    }

    // Called when the Drawing button is tapped mid-draw. Commits whatever has been drawn so far.
    private func finalizeManualDrawing() {
        if let layer = canvas.endManualDrawing() {
            currentDrawing?.addLayer(layer)
            undoOps.append(.added(layer))
            layerVersion += 1
            // isModified was already set true when the config was confirmed.
        } else {
            // No strokes were drawn — just cancel silently.
            canvas.cancelManualDrawing()
        }
        manualPrevTranslation    = .zero
        manualAccumulatedNotches = 0
        manualDirection          = 0
        manualJumpStep           = 0
        manualDragActive         = false
        manualCursorOutside      = false
    }
}

// MARK: - Supporting types

private enum LayerOp {
    case added(SpiroLayer)
    case deleted(SpiroLayer, at: Int)
}

private struct LayersSheetContext: Identifiable {
    let id = UUID()
    let drawing: SpiroDrawing  // captured at tap time; strong reference kept for sheet lifetime
}


#Preview {
    ContentView()
}
