import SwiftUI

// Equivalent to SpiroDialog / SpiroConfigViewController.
// Presented as a modal sheet; calls completion with the configured data, or nil on cancel.

struct SpiroConfigView: View {
    @State var data: SpiroDialogData
    let completion: (SpiroDialogData?) -> Void

    // Returns a user-facing message for the first violated constraint, or nil if valid.
    private var validationError: String? {
        if data.innerRingNotches < 1 { return "Inner ring notches must be at least 1." }
        if data.wheelNotches < 1     { return "Wheel notches must be at least 1." }
        if data.holeNumber < 1       { return "Hole number must be at least 1." }
        let maxHole = max(1, data.wheelNotches / 2 - SpiroCircle.invisibleHolesToEdge)
        if data.holeNumber > maxHole  { return "Hole number must be \(maxHole) or less for a \(data.wheelNotches)-notch wheel." }
        return nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Inner Ring Notches") {
                        TextField("Notches", value: $data.innerRingNotches, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                    LabeledContent("Wheel Notches") {
                        TextField("Notches", value: $data.wheelNotches, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                    LabeledContent("Hole Number") {
                        TextField("Hole", value: $data.holeNumber, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                    LabeledContent("Starting Notch") {
                        TextField("Notch", value: $data.startingNotch, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
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
            .navigationTitle("Add Layer")
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
