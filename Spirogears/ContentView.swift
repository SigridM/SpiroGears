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
    @State private var manualPrevTranslation: CGSize  = .zero
    @State private var manualAccumulatedNotches: Double = 0

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

            if showGears {
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

            HStack(spacing: 8) {
                Toggle("Gears", isOn: $showGears)
                    .disabled(manualDrawing)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .fixedSize()

                Button("Drawing") { showingDrawingMenu = true }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())

                Button { showingSettings = true } label: {
                    Image(systemName: "gearshape")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: Capsule())
            }
            .padding(.top, 60)
            .padding(.trailing, 16)

            // Manual drawing overlay — last in ZStack so it sits above the controls.
            // Color.clear captures drags; the Finish button sits on top of it.
            if canvas.isManualDrawing {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { handleManualDrag($0) }
                            .onEnded   { _ in manualPrevTranslation = .zero }
                    )

                VStack {
                    Spacer()
                    Button("Finish Layer") { finalizeManualDrawing() }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.regularMaterial, in: Capsule())
                        .padding(.bottom, 40)
                }
                .ignoresSafeArea()
            }
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
        let cs   = canvas.size

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

        // Skip degenerate vectors (finger right on the center, or no movement).
        guard hypot(Double(va.x), Double(va.y)) > 1,
              hypot(Double(vb.x), Double(vb.y)) > 1 else {
            manualPrevTranslation = value.translation
            return
        }

        // Signed angle from va to vb around the ring center (positive = clockwise).
        let cross = Double(va.x * vb.y - va.y * vb.x)
        let dot   = Double(va.x * vb.x + va.y * vb.y)
        let deltaAngle = atan2(cross, dot)  // radians

        // Convert angular delta to ring-tooth units (one tooth = one step).
        // Only accumulate forward (positive) motion so that a brief backward slip
        // of the finger doesn't require re-earning already-drawn steps.
        let deltaNotches = deltaAngle * Double(ring.innerNotchCircumference) / (2 * .pi)
        if deltaNotches > 0 {
            manualAccumulatedNotches += deltaNotches
        }

        let step = max(0, Int(manualAccumulatedNotches))
        canvas.updateManualDrawing(toStep: step)
        manualPrevTranslation = value.translation
    }

    // Called by the "Finish Layer" button. Commits whatever has been drawn so far.
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
    }
}

#Preview {
    ContentView()
}
