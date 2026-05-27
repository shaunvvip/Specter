import SwiftUI

struct ToggleRow: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        OptionRowEnvelope(entry: entry) {
            Toggle("", isOn: Binding(
                get: {
                    if case .bool(let b) = env.configModel.values[entry.key] { return b }
                    if case .bool(let b) = entry.defaultValue { return b }
                    return false
                },
                set: { env.configModel.set(entry.key, .bool($0)) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)
        }
    }
}
