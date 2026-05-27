import SwiftUI

struct StringRow: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        OptionRowEnvelope(entry: entry) {
            TextField("", text: Binding(
                get: {
                    if case .string(let s) = env.configModel.values[entry.key] { return s }
                    if case .string(let s) = entry.defaultValue { return s }
                    return ""
                },
                set: { env.configModel.set(entry.key, .string($0)) }
            ))
            .textFieldStyle(.roundedBorder)
            .frame(width: 140)
        }
    }
}
