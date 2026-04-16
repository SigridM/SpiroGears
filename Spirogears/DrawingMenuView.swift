import SwiftUI

// Equivalent to SpiroDrawingWorkspace's drawingMenu / drawingMenuItems.
// Presented as a sheet from ContentView.

struct DrawingMenuView: View {
    enum Action {
        case drawExample(Int)
        case drawNew
        case addLayer
        case undoLayer
        case redoLayer
        case save
        case drawSaved(String)
        case clear
    }

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
