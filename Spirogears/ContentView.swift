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
    @State private var showingDrawingMenu = false
    @State private var showingConfig = false
    @State private var showingSaveAlert = false
    @State private var saveNameInput = ""
    @State private var savedDrawingNames: [String] = []

    var body: some View {
        ZStack(alignment: .topTrailing) {
            SpiroCanvasView(canvas: canvas)
                .ignoresSafeArea()

            Button("Drawing") { showingDrawingMenu = true }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: Capsule())
                .padding(.top, 60)
                .padding(.trailing, 16)
        }
        .sheet(isPresented: $showingDrawingMenu) {
            NavigationStack {
                DrawingMenuView(savedDrawingNames: savedDrawingNames) { action in
                    handleMenuAction(action)
                }
            }
            .presentationDetents([.large, .medium])
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
            }
        }
        .task { savedDrawingNames = SpiroDrawing.savedDrawingNames }
        .alert("Save Drawing", isPresented: $showingSaveAlert) {
            TextField("Name", text: $saveNameInput)
            Button("Save") { confirmSave() }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Menu action handler

    private func handleMenuAction(_ action: DrawingMenuView.Action) {
        showingDrawingMenu = false
        switch action {
        case .drawExample(let n):
            switch n {
            case 1: drawExample(.example())
            case 4: drawExample(.example4())
            case 5: drawExample(.example5())
            default: break
            }
        case .drawNew:
            clear()
            currentDrawing = SpiroDrawing()
            showConfigAfterDismiss()
        case .addLayer:
            showConfigAfterDismiss()
        case .undoLayer:   undoLastLayer()
        case .redoLayer:   redoLastLayer()
        case .save:        saveDrawing()
        case .drawSaved(let name): drawSavedDrawing(named: name)
        case .clear:       clear()
        }
    }

    // Waits for the drawing menu sheet to finish dismissing before showing config.
    private func showConfigAfterDismiss() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            showingConfig = true
        }
    }

    // MARK: - Actions (equivalent to SpiroDrawingWorkspace methods)

    private func drawExample(_ drawing: SpiroDrawing) {
        clear()
        currentDrawing = drawing
        canvas.redrawAll(drawing: drawing)
    }

    private func drawSavedDrawing(named name: String) {
        guard let drawing = SpiroDrawing.savedDrawing(named: name) else { return }
        drawExample(drawing)
    }

    private func clear() {
        currentDrawing = nil
        currentDrawingName = ""
        undoneLayers.removeAll()
        canvas.clear()
    }

    private func undoLastLayer() {
        guard let drawing = currentDrawing,
              let layer = drawing.removeLastLayer() else { return }
        undoneLayers.append(layer)
        canvas.redrawAll(drawing: drawing)
    }

    private func redoLastLayer() {
        guard let drawing = currentDrawing,
              let layer = undoneLayers.popLast() else { return }
        drawing.addLayer(layer)
        canvas.appendLayer(layer)
    }

    private func saveDrawing() {
        guard currentDrawing != nil else { return }
        saveNameInput = currentDrawingName
        showingSaveAlert = true
    }

    private func confirmSave() {
        guard let drawing = currentDrawing, !saveNameInput.isEmpty else { return }
        SpiroDrawing.save(drawing, name: saveNameInput)
        currentDrawingName = saveNameInput
        savedDrawingNames = SpiroDrawing.savedDrawingNames
    }
}

#Preview {
    ContentView()
}
