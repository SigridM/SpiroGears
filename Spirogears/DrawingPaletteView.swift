import SwiftUI

// Bottom-of-screen drawing palette, replacing the Drawing menu button.
// Provides quick-access icon buttons for all common drawing actions.

struct DrawingPaletteView: View {
    let currentDrawing: SpiroDrawing?
    let savedDrawingNames: [String]
    let hasUndone: Bool
    let onAction: (DrawingMenuView.Action) -> Void

    @State private var showingLayers  = false
    @State private var showingLibrary = false

    private var hasLayers: Bool { !(currentDrawing?.layers.isEmpty ?? true) }

    var body: some View {
        HStack(spacing: 0) {
            PaletteButton(imageName: "AddDrawingIcon",  label: "New")    { onAction(.drawNew) }
            PaletteButton(imageName: "AddLayerIcon",    label: "Layer")  { onAction(.addLayer) }
                .disabled(currentDrawing == nil)
            PaletteButton(imageName: "UndoLayerIcon",   label: "Undo")   { onAction(.undoLayer) }
                .disabled(!hasLayers)
            PaletteButton(imageName: "RedoLayerIcon",   label: "Redo")   { onAction(.redoLayer) }
                .disabled(!hasUndone)
            PaletteButton(imageName: "EditLayersIcon",  label: "Layers") { showingLayers = true }
                .disabled(!hasLayers)
            PaletteButton(systemName: "square.and.arrow.down", label: "Save")    { onAction(.save) }
                .disabled(!hasLayers)
            PaletteButton(systemName: "trash",                 label: "Clear")   { onAction(.clear) }
            PaletteButton(systemName: "photo.stack",           label: "Library") { showingLibrary = true }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background {
            Rectangle()
                .fill(.regularMaterial)
                .ignoresSafeArea(edges: .bottom)
        }
        .sheet(isPresented: $showingLayers) {
            if let drawing = currentDrawing {
                NavigationStack {
                    LayersView(drawing: drawing, onAction: { action in
                        showingLayers = false
                        onAction(action)
                    })
                }
                .presentationDetents([.medium, .large])
            }
        }
        .sheet(isPresented: $showingLibrary) {
            NavigationStack {
                DrawingLibraryView(savedDrawingNames: savedDrawingNames, onAction: { action in
                    showingLibrary = false
                    onAction(action)
                })
            }
            .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Palette button

private struct PaletteButton: View {
    enum IconSource {
        case asset(String)
        case system(String)
    }

    let icon: IconSource
    let label: String
    let action: () -> Void

    init(imageName: String, label: String, action: @escaping () -> Void) {
        self.icon   = .asset(imageName)
        self.label  = label
        self.action = action
    }

    init(systemName: String, label: String, action: @escaping () -> Void) {
        self.icon   = .system(systemName)
        self.label  = label
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                switch icon {
                case .asset(let name):
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                case .system(let name):
                    Image(systemName: name)
                        .font(.system(size: 24))
                        .frame(width: 36, height: 36)
                }
                Text(label)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Library sheet (saved + preset drawings)

struct DrawingLibraryView: View {
    let savedDrawingNames: [String]
    let onAction: (DrawingMenuView.Action) -> Void

    var body: some View {
        List {
            if !savedDrawingNames.isEmpty {
                Section("Saved Drawings") {
                    ForEach(savedDrawingNames, id: \.self) { name in
                        Button(name) { onAction(.drawSaved(name)) }
                    }
                }
            }
            Section("Preset Drawings") {
                Button("Circle")   { onAction(.drawExample(1)) }
                Button("Star")     { onAction(.drawExample(4)) }
                Button("Triangle") { onAction(.drawExample(5)) }
            }
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
    }
}
