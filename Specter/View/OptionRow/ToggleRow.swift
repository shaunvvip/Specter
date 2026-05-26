import SwiftUI

struct ToggleRow: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env
    @State private var expanded = false

    var body: some View {
        OptionRowEnvelope(entry: entry, isExpanded: $expanded) {
            Toggle("", isOn: Binding(
                get: {
                    if case .bool(let b) = env.configModel.values[entry.key] { return b }
                    if case .bool(let b) = entry.defaultValue { return b }
                    return false
                },
                set: { env.configModel.set(entry.key, .bool($0)) }
            ))
            .labelsHidden()
        }
    }
}
