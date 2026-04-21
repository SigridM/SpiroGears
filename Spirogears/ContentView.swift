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
    @State private var undoneLayers: [SpiroLayer] = []
    @State private var isModified = false

    @AppStorage("showGears")      private var showGears      = true
    @AppStorage("animate")        private var animate        = false
    @AppStorage("animationSpeed") private var animationSpeed = AnimationSpeed.medium
    @AppStorage("manualDrawing")  private var manualDrawing  = false

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

    @State private var showingDrawingMenu = false
    @State private var showingConfig = false
    @State private var showingSettings = false
    @State private var showingSaveAlert = false
    @State private var showingSaveBeforeAction = false
    @State private var showingPresetNameError = false

    @State private var saveNameInput = ""
    @State private var savedDrawingNames: [String] = []
    @State private var pendingAction: DrawingMenuView.Action? = nil

    var body: some View {
        ZStack(alignment: .topTrailing) {
            SpiroCanvasView(canvas: canvas, scale: $canvasScale, lastScale: $canvasLastScale)
                .ignoresSafeArea()

            // During an active manual drag the gears always show so the user can
            // see where the wheel is; otherwise the Gears toggle governs visibility.
            if showGears || manualDragActive {
                let overlayLayer = canvas.animatingLayer
                                ?? (canvas.isManualDrawing ? canvas.manualLayer : nil)
                                ?? currentDrawing?.layers.last
                let overlayAngle = canvas.isManualDrawing
                                 ? canvas.manualWheelAngle
                                 : canvas.animationWheelAngle
                if let layer = overlayLayer {
                    GearOverlayView(layer: layer, wheelAngle: overlayAngle)
                        .scaleEffect(canvasScale)
                        .ignoresSafeArea()
                }
            }

            // Tap-to-skip overlay: captures a single tap anywhere on the canvas
            // during animation and completes the drawing instantly.
            if canvas.isAnimating {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture { canvas.skipAnimation() }
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
                                manualDragActive      = false
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

            HStack(spacing: 8) {
                Toggle("Gears", isOn: $showGears)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .fixedSize()

                Button("Drawing") {
                    if canvas.isManualDrawing { finalizeManualDrawing() }
                    showingDrawingMenu = true
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: Capsule())

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
            .padding(.trailing, 16)
        }
        .sheet(isPresented: $showingDrawingMenu) {
            NavigationStack {
                DrawingMenuView(currentDrawing: currentDrawing, savedDrawingNames: savedDrawingNames) { action in
                    handleMenuAction(action)
                }
            }
            .presentationDetents([.large, .medium])
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
                undoneLayers.removeAll()
                if manualDrawing {
                    // Don't commit to the drawing yet — wait for the drag to finish.
                    canvas.beginManualDrawing(layer: layer)
                    isModified = true
                } else if animate {
                    currentDrawing?.addLayer(layer)
                    canvas.animateLayer(layer, pointsPerFrame: animationSpeed.pointsPerFrame)
                    isModified = true
                } else {
                    currentDrawing?.addLayer(layer)
                    canvas.appendLayer(layer)
                    isModified = true
                }
            }
        }
        .task { savedDrawingNames = SpiroDrawing.savedDrawingNames }
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
        showingDrawingMenu = false

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
        case .drawExample, .drawNew, .drawSaved, .useAsTemplate, .clear:
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
            clear()
            currentDrawing = SpiroDrawing()
            showConfigAfterDismiss()
        case .addLayer:
            showConfigAfterDismiss()
        case .useAsTemplate(let data):
            clear()
            currentDrawing = SpiroDrawing()
            SpiroDialogData.lastData = data
            showConfigAfterDismiss()
        case .undoLayer:   undoLastLayer()
        case .redoLayer:   redoLastLayer()
        case .save:        saveDrawing()
        case .drawSaved(let name): loadSavedDrawing(named: name)
        case .clear:       clear()
        }
    }

    private func runPendingAction() {
        guard let action = pendingAction else { return }
        pendingAction = nil
        performAction(action)
    }

    // Waits for the drawing menu sheet to finish dismissing before showing config.
    private func showConfigAfterDismiss() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            showingConfig = true
        }
    }

    // MARK: - Actions

    private func loadDrawing(_ drawing: SpiroDrawing) {
        clear()
        currentDrawing = drawing
        if animate {
            canvas.animateDrawing(drawing, pointsPerFrame: animationSpeed.pointsPerFrame)
        } else {
            canvas.redrawAll(drawing: drawing)
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
        currentDrawing = nil
        currentDrawingName = ""
        undoneLayers.removeAll()
        isModified = false
        canvas.clear()
    }

    private func undoLastLayer() {
        guard let drawing = currentDrawing,
              let layer = drawing.removeLastLayer() else { return }
        undoneLayers.append(layer)
        isModified = true
        canvas.redrawAll(drawing: drawing)
    }

    private func redoLastLayer() {
        guard let drawing = currentDrawing,
              let layer = undoneLayers.popLast() else { return }
        drawing.addLayer(layer)
        isModified = true
        canvas.appendLayer(layer)
    }

    private func saveDrawing() {
        guard currentDrawing != nil else { return }
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
        currentDrawingName = saveNameInput
        savedDrawingNames = SpiroDrawing.savedDrawingNames
        isModified = false
        runPendingAction()
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
            // Wrap startFrac into [0, stepCount).
            let fwdNotches = ((startFrac.truncatingRemainder(dividingBy: Double(stepCount)))
                              + Double(stepCount))
                             .truncatingRemainder(dividingBy: Double(stepCount))
            // The jump step is the absolute step at which drawing will start.
            // For CW:  jumpStep = +fwdNotches (step advances positively)
            // For CCW: jumpStep = -(stepCount - fwdNotches), which places the wheel
            //          at the cursor position (step ≡ fwdNotches mod stepCount) and
            //          lets the CCW draw cover a full stepCount notches before finalizing.
            let jumpStep: Int
            if manualDirection > 0 {
                jumpStep = Int(fwdNotches)
            } else {
                jumpStep = -(stepCount - Int(fwdNotches))
            }
            manualJumpStep           = jumpStep
            manualAccumulatedNotches = 0          // always counts 0 → stepCount from jump
            canvas.jumpManualStep(to: jumpStep)
        }
        guard manualDirection != 0 else {
            manualPrevTranslation = value.translation
            return
        }

        let stepCount = layer.stepCount
        let deltaNotches = deltaAngle * Double(ring.innerNotchCircumference) / (2 * .pi)
                         * Double(manualDirection)
        manualAccumulatedNotches = max(0, min(Double(stepCount),
                                              manualAccumulatedNotches + deltaNotches))
        let rawStep = Int(manualAccumulatedNotches)
        // Absolute step: start at jumpStep and advance by rawStep in the chosen direction.
        // This ensures the user always draws exactly stepCount notches regardless of where
        // they start, fixing the instant-finalize bug when starting CCW near 12 o'clock.
        let step = manualJumpStep + manualDirection * rawStep
        // updateManualDrawing sets manualWheelAngle = ring.angleIncrement * step.
        // The wheel-center orbital angle thereby advances at exactly the same angular
        // rate as the finger, keeping the gear body in sync with the cursor.
        canvas.updateManualDrawing(toStep: step)
        manualPrevTranslation = value.translation
    }

    // Called when the Drawing button is tapped mid-draw, or when the wheel
    // completes a full cycle. Commits whatever has been drawn so far.
    private func finalizeManualDrawing() {
        if let layer = canvas.endManualDrawing() {
            currentDrawing?.addLayer(layer)
            // isModified was already set true when the config was confirmed.
        } else {
            // No strokes were drawn — just cancel silently.
            canvas.cancelManualDrawing()
        }
        manualPrevTranslation    = .zero
        manualAccumulatedNotches = 0
        manualDirection          = 0
        manualJumpStep           = 0
    }
}

#Preview {
    ContentView()
}
