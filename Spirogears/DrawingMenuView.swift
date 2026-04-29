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
        case deleteSaved(String)
        case clear
        // Layer editing (subscribers only)
        case deleteLayer(Int)
        case toggleLayerHidden(Int)
        case moveLayer(IndexSet, Int)
        case reconfigureLayer(Int, SpiroDialogData)
    }

    let currentDrawing: SpiroDrawing?
    let savedDrawingNames: [String]
    let hasUndone: Bool
    let onAction: (Action) -> Void

    private var hasLayers: Bool { !(currentDrawing?.layers.isEmpty ?? true) }

    var body: some View {
        List {
            Section {
                Button("Draw New...")  { onAction(.drawNew) }
                Button("Add Layer...") { onAction(.addLayer) }
                    .disabled(currentDrawing == nil)
                Button("Undo Layer")   { onAction(.undoLayer) }
                    .disabled(!hasLayers)
                Button("Redo Layer")   { onAction(.redoLayer) }
                    .disabled(!hasUndone)
                Button("Save...")      { onAction(.save) }
                    .disabled(!hasLayers)
                if hasLayers {
                    NavigationLink("Show Layers") {
                        LayersView(drawing: currentDrawing!, layerVersion: 0, isSubscribed: false, onAction: onAction)
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
            Section("Preset Drawings") {
                Button("Circle")   { onAction(.drawExample(1)) }
                Button("Star")     { onAction(.drawExample(4)) }
                Button("Triangle") { onAction(.drawExample(5)) }
            }
        }
        .navigationTitle("Drawing")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Layers detail view

// Pure-value snapshot of one layer. Storing only value types in ForEach data
// eliminates any risk of class references becoming dangling before SwiftUI
// lazily evaluates row bodies (seen as PAC failures on ARM64e / iOS 26 beta).
private struct LayerInfo: Identifiable {
    let id: Int   // layer index — serves as ForEach identity
    let number: Int
    let innerRingNotches: Int
    let wheelNotches: Int
    let holeNumber: Int
    let startingNotch: Int
    let penColor: Color
    let isHidden: Bool
    let dialogData: SpiroDialogData
}

struct LayersView: View {
    let drawing: SpiroDrawing
    let layerVersion: Int          // incremented by ContentView after each edit to force re-render
    let isSubscribed: Bool         // passed explicitly — avoids @Environment class-reference issues
    let onAction: (DrawingMenuView.Action) -> Void

    // Snapshot taken while `drawing` is guaranteed alive (body evaluation time).
    // The resulting array is pure value types — no SpiroLayer class references.
    private var layerInfos: [LayerInfo] {
        drawing.layers.indices.map { index in
            let layer  = drawing.layers[index]
            let innerN = layer.stationaryGuide.innerNotchCircumference
            let wheelN = layer.penGuide.outerNotchCircumference
            let holeN  = layer.penGuide.storedHoleNumber
            let startN = layer.stationaryGuide.startingNotch
            let color  = Color(uiColor: layer.penColor)
            return LayerInfo(
                id:               index,
                number:           index + 1,
                innerRingNotches: innerN,
                wheelNotches:     wheelN,
                holeNumber:       holeN,
                startingNotch:    startN,
                penColor:         color,
                isHidden:         layer.isHidden,
                dialogData:       SpiroDialogData(innerRingNotches: innerN,
                                                  wheelNotches:     wheelN,
                                                  color:            color,
                                                  holeNumber:       holeN,
                                                  startingNotch:    startN,
                                                  loops:            layer.loops)
            )
        }
    }

    @State private var editMode: EditMode = .inactive

    private var isReordering: Bool { editMode == .active }

    var body: some View {
        List {
            ForEach(layerInfos) { info in
                LayerRow(
                    number:           info.number,
                    innerRingNotches: info.innerRingNotches,
                    wheelNotches:     info.wheelNotches,
                    holeNumber:       info.holeNumber,
                    startingNotch:    info.startingNotch,
                    penColor:         info.penColor,
                    isHidden:         info.isHidden,
                    dialogData:       info.dialogData,
                    layerIndex:       info.id,
                    isSubscribed:     isSubscribed,
                    isReordering:     isReordering,
                    onAction:         onAction
                )
            }
            .onDelete(perform: isSubscribed ? { indexSet in
                for index in indexSet { onAction(.deleteLayer(layerInfos[index].id)) }
            } : nil)
            .onMove(perform: isSubscribed ? { source, destination in
                onAction(.moveLayer(source, destination))
            } : nil)
        }
        .environment(\.editMode, $editMode)
        .navigationTitle("Layers")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isSubscribed {
                ToolbarItem(placement: .navigationBarTrailing) { EditButton() }
            }
        }
    }
}

// All properties are value types — no class references that can become dangling.
private struct LayerRow: View {
    let number: Int
    let innerRingNotches: Int
    let wheelNotches: Int
    let holeNumber: Int
    let startingNotch: Int
    let penColor: Color
    let isHidden: Bool
    let dialogData: SpiroDialogData
    let layerIndex: Int
    let isSubscribed: Bool
    let isReordering: Bool
    let onAction: (DrawingMenuView.Action) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Circle()
                .fill(penColor)
                .frame(width: 16, height: 16)
                .opacity(isHidden ? 0.3 : 1.0)

            VStack(alignment: .leading, spacing: 4) {
                Text("Layer \(number)")
                    .font(.headline)
                    .foregroundStyle(isHidden ? .secondary : .primary)
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 2) {
                    GridRow {
                        label("Inner ring"); value(innerRingNotches)
                        label("Wheel");      value(wheelNotches)
                    }
                    GridRow {
                        label("Hole");       value(holeNumber)
                        label("Start");      value(startingNotch)
                    }
                }
                .font(.caption)
            }

            Spacer()

            if isSubscribed && !isReordering {
                Button {
                    onAction(.toggleLayerHidden(layerIndex))
                } label: {
                    Image(systemName: isHidden ? "eye.slash" : "eye")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Button {
                    onAction(.reconfigureLayer(layerIndex, dialogData))
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .padding(.leading, 8)

                Button {
                    onAction(.useAsTemplate(dialogData))
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .padding(.leading, 8)
            } else if !isReordering {
                Button("Use as template") {
                    onAction(.useAsTemplate(dialogData))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
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
