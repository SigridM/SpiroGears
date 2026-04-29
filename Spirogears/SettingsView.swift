import SwiftUI

// MARK: - Animation speed preference

enum AnimationSpeed: String, CaseIterable, Identifiable {
    case slow, medium, fast
    var id: Self { self }
    var label: String { rawValue.capitalized }
    var pointsPerFrame: Int {
        switch self {
        case .slow:   return 2
        case .medium: return 10
        case .fast:   return 20
        }
    }
}

// MARK: - Settings form

struct SettingsView: View {
    @AppStorage("showGears")             private var showGears             = true
    @AppStorage("animate")               private var animate               = false
    @AppStorage("animationSpeed")        private var animationSpeed        = AnimationSpeed.medium
    @AppStorage("manualDrawing")         private var manualDrawing         = false
    @AppStorage("haptics")               private var haptics               = true
    @AppStorage("defaultBackgroundColor") private var defaultBackgroundColorHex: String = "#FFFFFF"

    @Environment(SubscriptionStore.self) private var store

    private var defaultBackgroundColorBinding: Binding<Color> {
        Binding(
            get: { Color(uiColor: UIColor(hex: defaultBackgroundColorHex) ?? .white) },
            set: { defaultBackgroundColorHex = UIColor($0).hexString }
        )
    }

    var body: some View {
        Form {
            Section("Drawing") {
                Picker("Drawing", selection: $manualDrawing) {
                    Text("Manual").tag(true)
                    Text("Automatic").tag(false)
                }
                .pickerStyle(.inline)
                .labelsHidden()
                .onChange(of: manualDrawing) { _, on in
                    if on { animate = false }
                }

                if !manualDrawing {
                    Toggle("Animate", isOn: $animate)
                        .padding(.leading, 20)
                    Picker("Speed", selection: $animationSpeed) {
                        ForEach(AnimationSpeed.allCases) { speed in
                            Text(speed.label).tag(speed)
                        }
                    }
                    .disabled(!animate)
                    .padding(.leading, 20)
                }
            }

            Section("Feedback") {
                Toggle("Haptics", isOn: $haptics)
            }

            Section("Canvas") {
                HStack {
                    Text("Default Background Color")
                    Spacer()
                    ColorPicker("Default Background Color", selection: defaultBackgroundColorBinding)
                        .labelsHidden()
                }
            }

            if store.entitlement == .subscribed {
                Section {
                    Button("Manage Subscription") {
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
