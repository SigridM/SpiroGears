import SwiftUI

// Equivalent to SpiroDialog / SpiroConfigViewController.
// Presented as a modal sheet; calls completion with the configured data, or nil on cancel.

struct SpiroConfigView: View {
    @State var data: SpiroDialogData
    var title: String = "Add Layer"
    let completion: (SpiroDialogData?) -> Void

    enum Field { case innerRing, wheelNotches, holeNumber, startingNotch, loops }
    @FocusState private var focusedField: Field?

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

    // String binding for the loops field.
    // When loops is nil (full cycle), the field displays the totalLoops count in grey
    // so there is always a visible number to tap. Clearing the field returns to nil.
    private var loopsText: Binding<String> {
        Binding(
            get: { data.loops.map { "\($0)" } ?? "\(data.totalLoops)" },
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
                    numberRow(
                        label: "Inner Ring Notches",
                        subtitle: "min \(data.wheelNotches + 1)",
                        value: $data.innerRingNotches,
                        minValue: data.wheelNotches + 1,
                        field: .innerRing
                    )
                    numberRow(
                        label: "Wheel Notches",
                        subtitle: "max \(maxWheelNotches)",
                        value: $data.wheelNotches,
                        minValue: 1,
                        maxValue: maxWheelNotches,
                        field: .wheelNotches
                    )
                    numberRow(
                        label: "Hole Number",
                        subtitle: "max \(maxHole)",
                        value: $data.holeNumber,
                        minValue: 1,
                        maxValue: maxHole,
                        field: .holeNumber
                    )
                    numberRow(
                        label: "Starting Notch",
                        value: $data.startingNotch,
                        minValue: 0,
                        maxValue: data.innerRingNotches - 1,
                        field: .startingNotch
                    )
                    loopsRow
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

    // A form row with a tappable label area and −/+ buttons flanking the text field.
    @ViewBuilder
    private func numberRow(
        label: String,
        subtitle: String? = nil,
        value: Binding<Int>,
        minValue: Int = 1,
        maxValue: Int = 9999,
        field: Field
    ) -> some View {
        HStack(spacing: 8) {
            // Label — tap anywhere here to focus the text field.
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                if let sub = subtitle {
                    Text(sub)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { focusedField = field }

            Button {
                value.wrappedValue = max(minValue, value.wrappedValue - 1)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .imageScale(.large)
            }
            .buttonStyle(.borderless)
            .disabled(value.wrappedValue <= minValue)

            TextField("", value: value, format: .number)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .focused($focusedField, equals: field)
                .frame(width: 52)

            Button {
                value.wrappedValue = min(maxValue, value.wrappedValue + 1)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .imageScale(.large)
            }
            .buttonStyle(.borderless)
            .disabled(value.wrappedValue >= maxValue)
        }
    }

    // Loops uses an optional Int, so it gets its own row.
    // When nil the field shows the full-cycle count in grey; stepper buttons operate
    // relative to that baseline so there is always something visible to tap or adjust.
    private var loopsRow: some View {
        let base = data.loops ?? data.totalLoops
        return HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Loops")
                if data.loops != nil {
                    Button("full cycle") { data.loops = nil }
                        .font(.caption)
                        .buttonStyle(.borderless)
                } else {
                    Text("full cycle: \(data.totalLoops)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { focusedField = .loops }

            Button {
                let decremented = base - 1
                data.loops = decremented == data.totalLoops ? nil : decremented
            } label: {
                Image(systemName: "minus.circle.fill")
                    .imageScale(.large)
            }
            .buttonStyle(.borderless)
            .disabled(base <= 1)

            TextField("", text: loopsText)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .loops)
                .foregroundStyle(data.loops == nil ? .secondary : .primary)
                .frame(width: 52)

            Button {
                data.loops = base + 1
            } label: {
                Image(systemName: "plus.circle.fill")
                    .imageScale(.large)
            }
            .buttonStyle(.borderless)
        }
    }
}
