import SwiftUI

struct EnumRow: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        OptionRowEnvelope(entry: entry) {
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
                .frame(width: 140)
            }
        }
    }
}
