import SwiftUI

struct StringRow: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env
    @State private var expanded = false

    var body: some View {
        OptionRowEnvelope(entry: entry, isExpanded: $expanded) {
            TextField("", text: Binding(
                get: {
                    if case .string(let s) = env.configModel.values[entry.key] { return s }
                    if case .string(let s) = entry.defaultValue { return s }
                    return ""
                },
                set: { env.configModel.set(entry.key, .string($0)) }
            ))
            .textFieldStyle(.roundedBorder)
        }
    }
}
