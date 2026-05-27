import SwiftUI

struct ToggleRow: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env

    private var defaultBool: Bool {
        if case .bool(let b) = entry.defaultValue { return b }
        return false
    }

    var body: some View {
        OptionRowEnvelope(entry: entry) {
            Toggle("", isOn: Binding(
                get: { env.configModel.bool(for: entry.key, default: defaultBool) },
                set: { env.configModel.set(entry.key, .bool($0)) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)
        }
    }
}
