import SwiftUI

struct ThemeRow: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env
    @State private var expanded = false

    var body: some View {
        OptionRowEnvelope(entry: entry, isExpanded: $expanded) {
            Picker("", selection: Binding(
                get: {
                    if case .string(let s) = env.configModel.values[entry.key] { return s }
                    return ""
                },
                set: { newValue in
                    env.configModel.set(entry.key, .string(newValue))
                    // Re-load theme file so the preview pane redraws with the new palette.
                    Task { await env.reloadCurrentThemeColors() }
                }
            )) {
                Text("(default)").tag("")
                ForEach(env.availableThemes, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
    }
}
