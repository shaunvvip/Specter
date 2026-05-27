import SwiftUI

struct SliderRow: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        OptionRowEnvelope(entry: entry) {
            switch entry.type {
            case .integer(let range):
                HStack(spacing: 8) {
                    Slider(value: Binding(
                        get: { Double(currentInt(range: range)) },
                        set: { env.configModel.set(entry.key, .integer(Int($0))) }
                    ), in: Double(range.lowerBound)...Double(range.upperBound), step: 1)
                    .frame(width: 64)
                    .controlSize(.small)
                    ValueChip(text: String(currentInt(range: range)),
                              isDirty: env.configModel.dirtyKeys.contains(entry.key))
                }
            case .double(let range):
                HStack(spacing: 8) {
                    Slider(value: Binding(
                        get: { currentDouble(range: range) },
                        set: { env.configModel.set(entry.key, .double($0)) }
                    ), in: range, step: 0.01)
                    .frame(width: 64)
                    .controlSize(.small)
                    ValueChip(text: String(format: "%.2f", currentDouble(range: range)),
                              isDirty: env.configModel.dirtyKeys.contains(entry.key))
                }
            default:
                ValueChip(text: "—")
            }
        }
    }

    private func currentInt(range: ClosedRange<Int>) -> Int {
        if case .integer(let i) = env.configModel.values[entry.key] { return i }
        if case .integer(let i) = entry.defaultValue { return i }
        return range.lowerBound
    }

    private func currentDouble(range: ClosedRange<Double>) -> Double {
        if case .double(let d) = env.configModel.values[entry.key] { return d }
        if case .double(let d) = entry.defaultValue { return d }
        return range.lowerBound
    }
}
