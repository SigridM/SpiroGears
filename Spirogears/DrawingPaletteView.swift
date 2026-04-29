import SwiftUI

// Bottom-of-screen drawing palette, replacing the Drawing menu button.
// Provides quick-access icon buttons for all common drawing actions.

struct DrawingPaletteView: View {
    let currentDrawing: SpiroDrawing?
    let savedDrawingNames: [String]
    let thumbnails: [String: UIImage]
    let hasUndo: Bool
    let hasUndone: Bool
    let onAction: (DrawingMenuView.Action) -> Void
    let onShowLayers: () -> Void

    @State private var showingLibrary = false

    private var hasLayers: Bool { !(currentDrawing?.layers.isEmpty ?? true) }

    var body: some View {
        HStack(spacing: 0) {
            PaletteButton(imageName: "AddDrawingIcon",  label: "New")    { onAction(.drawNew) }
            PaletteButton(imageName: "AddLayerIcon",    label: "Layer")  { onAction(.addLayer) }
                .disabled(currentDrawing == nil)
            PaletteButton(imageName: "UndoLayerIcon",   label: "Undo")   { onAction(.undoLayer) }
                .disabled(!hasUndo)
            PaletteButton(imageName: "RedoLayerIcon",   label: "Redo")   { onAction(.redoLayer) }
                .disabled(!hasUndone)
            PaletteButton(imageName: "EditLayersIcon",  label: "Layers") { onShowLayers() }
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
        .sheet(isPresented: $showingLibrary) {
            NavigationStack {
                DrawingLibraryView(
                    savedDrawingNames: savedDrawingNames,
                    thumbnails: thumbnails,
                    onAction: { action in
                        showingLibrary = false
                        onAction(action)
                    }
                )
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
    let thumbnails: [String: UIImage]
    let onAction: (DrawingMenuView.Action) -> Void

    @State private var viewMode: ViewMode = .list
    @State private var searchText = ""

    enum ViewMode { case list, grid }

    private static let presets: [(name: String, action: DrawingMenuView.Action)] = [
        ("Circle",   .drawExample(1)),
        ("Star",     .drawExample(4)),
        ("Triangle", .drawExample(5))
    ]

    private var filteredSaved: [String] {
        searchText.isEmpty ? savedDrawingNames
                           : savedDrawingNames.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $viewMode) {
                Image(systemName: "list.bullet").tag(ViewMode.list)
                Image(systemName: "square.grid.2x2").tag(ViewMode.grid)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            switch viewMode {
            case .list: listContent
            case .grid: gridContent
            }
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search saved drawings")
    }

    // MARK: List view

    private var listContent: some View {
        List {
            if !filteredSaved.isEmpty {
                Section("Saved Drawings") {
                    ForEach(filteredSaved, id: \.self) { name in
                        Button(name) { onAction(.drawSaved(name)) }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    onAction(.deleteSaved(name))
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            Section("Preset Drawings") {
                ForEach(Self.presets, id: \.name) { preset in
                    Button(preset.name) { onAction(preset.action) }
                }
            }
        }
    }

    // MARK: Grid view

    private var gridContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !filteredSaved.isEmpty {
                    gridSection(
                        title: "Saved Drawings",
                        items: filteredSaved.map { ($0, .drawSaved($0)) },
                        isDeletable: true
                    )
                }
                gridSection(
                    title: "Preset Drawings",
                    items: Self.presets.map { ($0.name, $0.action) },
                    isDeletable: false
                )
            }
            .padding()
        }
    }

    private func gridSection(
        title: String,
        items: [(name: String, action: DrawingMenuView.Action)],
        isDeletable: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 90), spacing: 12)],
                spacing: 14
            ) {
                ForEach(items, id: \.name) { name, action in
                    thumbnailCell(name: name, action: action, isDeletable: isDeletable)
                }
            }
        }
    }

    private func thumbnailCell(
        name: String,
        action: DrawingMenuView.Action,
        isDeletable: Bool
    ) -> some View {
        Button { onAction(action) } label: {
            VStack(spacing: 5) {
                Group {
                    if let thumb = thumbnails[name] {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color.secondary.opacity(0.15)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            )
                    }
                }
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.separator, lineWidth: 0.5)
                )

                Text(name)
                    .font(.caption2)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 90)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            if isDeletable {
                Button(role: .destructive) {
                    onAction(.deleteSaved(name))
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}
