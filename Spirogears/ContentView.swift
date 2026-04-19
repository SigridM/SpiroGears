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

    @AppStorage("showGears") private var showGears = true

    // Zoom state lifted from SpiroCanvasView so GearOverlayView can share the same scale
    @State private var canvasScale: CGFloat = 1.0
    @State private var canvasLastScale: CGFloat = 1.0

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

            if showGears, let layer = currentDrawing?.layers.last {
                GearOverlayView(layer: layer)
                    .scaleEffect(canvasScale)
                    .ignoresSafeArea()
            }

            HStack(spacing: 8) {
                Toggle("Gears", isOn: $showGears)
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
                currentDrawing?.addLayer(layer)
                undoneLayers.removeAll()
                canvas.appendLayer(layer)
                isModified = true
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
        canvas.redrawAll(drawing: drawing)
        // isModified stays false — just loaded, nothing changed yet
    }

    private func loadSavedDrawing(named name: String) {
        guard let drawing = SpiroDrawing.savedDrawing(named: name) else { return }
        loadDrawing(drawing)
        currentDrawingName = name
    }

    private func clear() {
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
}

#Preview {
    ContentView()
}
