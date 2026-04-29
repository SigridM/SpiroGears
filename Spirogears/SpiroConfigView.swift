import SwiftUI

// Equivalent to SpiroDialog / SpiroConfigViewController.
// Presented as a modal sheet; calls completion with the configured data, or nil on cancel.

struct SpiroConfigView: View {
    @State var data: SpiroDialogData
    var title: String = "Add Layer"
    let completion: (SpiroDialogData?) -> Void

    private var maxHole: Int {
        max(1, data.wheelNotches / 2 - SpiroCircle.invisibleHolesToEdge)
    }

    private var maxWheelNotches: Int {
        max(1, data.innerRingNotches - 1)
    }

    // Returns a user-facing message for the first violated constraint, or nil if valid.
    private var validationError: String? {
        if data.innerRingNotches < 1 { return "Inner ring notches must be at least 1." }
        if data.wheelNotches < 1     { return "Wheel notches must be at least 1." }
        if data.wheelNotches >= data.innerRingNotches { return "Wheel notches must be less than inner ring notches (\(data.innerRingNotches))." }
        if data.holeNumber < 1       { return "Hole number must be at least 1." }
        if data.holeNumber > maxHole  { return "Hole number must be \(maxHole) or less for a \(data.wheelNotches)-notch wheel." }
        if let n = data.loops, n < 1 { return "Loops must be at least 1, or blank for a full cycle." }
        return nil
    }

    // String binding for the optional loops field.
    private var loopsText: Binding<String> {
        Binding(
            get: { data.loops.map { "\($0)" } ?? "" },
            set: { newValue in
                if newValue.isEmpty {
                    data.loops = nil
                } else if let n = Int(newValue) {
                    data.loops = n
                }
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent {
                        TextField("Notches", value: $data.innerRingNotches, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Inner Ring Notches")
                            Text("min \(data.wheelNotches + 1)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    LabeledContent {
                        TextField("Notches", value: $data.wheelNotches, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Wheel Notches")
                            Text("max \(maxWheelNotches)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    LabeledContent {
                        TextField("Hole", value: $data.holeNumber, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hole Number")
                            Text("max \(maxHole)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    LabeledContent("Starting Notch") {
                        TextField("Notch", value: $data.startingNotch, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                    LabeledContent {
                        TextField("# of loops", text: loopsText)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Loops")
                            Text("full cycle: \(data.totalLoops)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    ColorPicker("Color", selection: $data.color)
                }
                if let error = validationError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { completion(nil) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") {
                        SpiroDialogData.lastData = data
                        completion(data)
                    }
                    .disabled(validationError != nil)
                }
            }
        }
    }
}
