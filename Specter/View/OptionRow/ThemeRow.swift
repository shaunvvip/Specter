import SwiftUI

struct ThemeRow: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        OptionRowEnvelope(entry: entry) {
            Picker("", selection: Binding(
                get: {
                    if case .string(let s) = env.configModel.values[entry.key] { return s }
                    return ""
                },
                set: { newValue in
                    env.configModel.set(entry.key, .string(newValue))
                    Task { await env.reloadCurrentThemeColors() }
                }
            )) {
                Text("Browse \(env.availableThemes.count)").tag("")
                ForEach(env.availableThemes, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 160)
        }
    }
}
