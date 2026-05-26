import SwiftUI

struct SliderRow: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env
    @State private var expanded = false

    var body: some View {
        OptionRowEnvelope(entry: entry, isExpanded: $expanded) {
            switch entry.type {
            case .integer(let range):
                HStack {
                    Slider(value: Binding(
                        get: {
                            if case .integer(let i) = env.configModel.values[entry.key] { return Double(i) }
                            if case .integer(let i) = entry.defaultValue { return Double(i) }
                            return Double(range.lowerBound)
                        },
                        set: { env.configModel.set(entry.key, .integer(Int($0))) }
                    ), in: Double(range.lowerBound)...Double(range.upperBound), step: 1)
                    Text(currentInt(range: range)).font(.caption.monospacedDigit()).frame(width: 32)
                }
            case .double(let range):
                HStack {
                    Slider(value: Binding(
                        get: {
                            if case .double(let d) = env.configModel.values[entry.key] { return d }
                            if case .double(let d) = entry.defaultValue { return d }
                            return range.lowerBound
                        },
                        set: { env.configModel.set(entry.key, .double($0)) }
                    ), in: range, step: 0.01)
                    Text(currentDouble(range: range)).font(.caption.monospacedDigit()).frame(width: 40)
                }
            default:
                Text("unsupported")
            }
        }
    }

    private func currentInt(range: ClosedRange<Int>) -> String {
        if case .integer(let i) = env.configModel.values[entry.key] { return String(i) }
        if case .integer(let i) = entry.defaultValue { return String(i) }
        return String(range.lowerBound)
    }

    private func currentDouble(range: ClosedRange<Double>) -> String {
        if case .double(let d) = env.configModel.values[entry.key] { return String(format: "%.2f", d) }
        if case .double(let d) = entry.defaultValue { return String(format: "%.2f", d) }
        return String(format: "%.2f", range.lowerBound)
    }
}
