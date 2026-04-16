import SwiftUI

// Equivalent to SpiroDialog / SpiroConfigViewController.
// Presented as a modal sheet; calls completion with the configured data, or nil on cancel.

struct SpiroConfigView: View {
    @State var data: SpiroDialogData
    let completion: (SpiroDialogData?) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Outer Ring Notches") {
                        TextField("Notches", value: $data.outerRingNotches, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
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
                    // Starting notch can be negative, so use the default keyboard
                    LabeledContent("Starting Notch") {
                        TextField("Notch", value: $data.startingNotch, format: .number)
                            .multilineTextAlignment(.trailing)
                    }
                    ColorPicker("Color", selection: $data.color)
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
                }
            }
        }
    }
}
