import SwiftUI

struct EnumRow: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env
    @State private var expanded = false

    var body: some View {
        OptionRowEnvelope(entry: entry, isExpanded: $expanded) {
            if case .enumeration(let cases) = entry.type {
                Picker("", selection: Binding(
                    get: {
                        if case .string(let s) = env.configModel.values[entry.key] { return s }
                        if case .string(let s) = entry.defaultValue { return s }
                        return cases.first ?? ""
                    },
                    set: { env.configModel.set(entry.key, .string($0)) }
                )) {
                    ForEach(cases, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
        }
    }
}
