import SwiftUI

// MARK: - Animation speed preference

enum AnimationSpeed: String, CaseIterable, Identifiable {
    case slow, medium, fast
    var id: Self { self }
    var label: String { rawValue.capitalized }
    var pointsPerFrame: Int {
        switch self {
        case .slow:   return 10
        case .medium: return 30
        case .fast:   return 100
        }
    }
}

// MARK: - Settings form

struct SettingsView: View {
    @AppStorage("showGears")      private var showGears      = true
    @AppStorage("animate")        private var animate        = false
    @AppStorage("animationSpeed") private var animationSpeed = AnimationSpeed.medium
    @AppStorage("manualDrawing")  private var manualDrawing  = false
    @AppStorage("haptics")        private var haptics        = true

    var body: some View {
        Form {
            Section("Drawing") {
                Toggle("Show Gears", isOn: $showGears)
                    .disabled(manualDrawing)    // locked on when Manual Drawing is enabled
                Toggle("Manual Drawing", isOn: $manualDrawing)
                    .onChange(of: manualDrawing) { _, on in
                        if on { showGears = true; animate = false }
                    }
            }

            Section("Animation") {
                Toggle("Animate", isOn: $animate)
                    .disabled(manualDrawing)    // incompatible with Manual Drawing
                Picker("Speed", selection: $animationSpeed) {
                    ForEach(AnimationSpeed.allCases) { speed in
                        Text(speed.label).tag(speed)
                    }
                }
                .disabled(!animate || manualDrawing)
            }

            Section("Feedback") {
                Toggle("Haptics", isOn: $haptics)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
