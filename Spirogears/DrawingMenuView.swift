import SwiftUI

// Equivalent to SpiroDrawingWorkspace's drawingMenu / drawingMenuItems.
// Presented as a sheet from ContentView.

struct DrawingMenuView: View {
    enum Action {
        case drawExample(Int)
        case drawNew
        case addLayer
        case useAsTemplate(SpiroDialogData)
        case undoLayer
        case redoLayer
        case save
        case drawSaved(String)
        case clear
    }

    let currentDrawing: SpiroDrawing?
    let savedDrawingNames: [String]
    let onAction: (Action) -> Void

    var body: some View {
        List {
            Section("Preset Drawings") {
                Button("Circle")   { onAction(.drawExample(1)) }
                Button("Star")     { onAction(.drawExample(4)) }
                Button("Triangle") { onAction(.drawExample(5)) }
            }
            Section {
                Button("Draw New...")  { onAction(.drawNew) }
                Button("Add Layer...") { onAction(.addLayer) }
                Button("Undo Layer")   { onAction(.undoLayer) }
                Button("Redo Layer")   { onAction(.redoLayer) }
                Button("Save...")      { onAction(.save) }
                if let drawing = currentDrawing, !drawing.layers.isEmpty {
                    NavigationLink("Show Layers") {
                        LayersView(drawing: drawing, onAction: onAction)
                    }
                }
            }
            if !savedDrawingNames.isEmpty {
                Section("Saved Drawings") {
                    ForEach(savedDrawingNames, id: \.self) { name in
                        Button(name) { onAction(.drawSaved(name)) }
                    }
                }
            }
            Section {
                Button("Clear", role: .destructive) { onAction(.clear) }
            }
        }
        .navigationTitle("Drawing")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Layers detail view

struct LayersView: View {
    let drawing: SpiroDrawing
    let onAction: (DrawingMenuView.Action) -> Void

    var body: some View {
        List {
            ForEach(Array(drawing.layers.enumerated()), id: \.offset) { index, layer in
                LayerRow(number: index + 1, layer: layer, onAction: onAction)
            }
        }
        .navigationTitle("Layers")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LayerRow: View {
    let number: Int
    let layer: SpiroLayer
    let onAction: (DrawingMenuView.Action) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Circle()
                .fill(Color(uiColor: layer.penColor))
                .frame(width: 16, height: 16)

            VStack(alignment: .leading, spacing: 4) {
                Text("Layer \(number)").font(.headline)
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 2) {
                    GridRow {
                        label("Outer ring"); value(layer.stationaryGuide.outerNotchCircumference)
                        label("Inner ring"); value(layer.stationaryGuide.innerNotchCircumference)
                    }
                    GridRow {
                        label("Wheel");     value(layer.penGuide.outerNotchCircumference)
                        label("Hole");      value(layer.penGuide.storedHoleNumber)
                    }
                    if layer.stationaryGuide.startingNotch != 0 {
                        GridRow {
                            label("Start"); value(layer.stationaryGuide.startingNotch)
                            Color.clear; Color.clear
                        }
                    }
                }
                .font(.caption)
            }

            Spacer()

            Button("Use as template") {
                onAction(.useAsTemplate(SpiroDialogData(from: layer)))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }

    private func label(_ text: String) -> some View {
        Text(text).foregroundStyle(.secondary)
    }

    private func value(_ n: Int) -> some View {
        Text("\(n)").monospacedDigit()
    }
}
