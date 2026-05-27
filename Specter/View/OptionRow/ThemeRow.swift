import SwiftUI

struct ThemeRow: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env

    private var current: String {
        if case .string(let s) = env.configModel.values[entry.key] { return s }
        return ""
    }

    var body: some View {
        OptionRowEnvelope(entry: entry) {
            Menu {
                Button(current.isEmpty ? "✓ (default)" : "(default)") {
                    env.configModel.set(entry.key, .string(""))
                    Task { await env.reloadCurrentThemeColors() }
                }
                Divider()
                ForEach(env.availableThemes, id: \.self) { name in
                    Button(name == current ? "✓ \(name)" : name) {
                        env.configModel.set(entry.key, .string(name))
                        Task { await env.reloadCurrentThemeColors() }
                    }
                }
            } label: {
                ValueChip(
                    text: current.isEmpty ? "Browse \(env.availableThemes.count)" : truncate(current, 14),
                    isAction: current.isEmpty,
                    isDirty: env.configModel.dirtyKeys.contains(entry.key)
                )
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }

    private func truncate(_ s: String, _ n: Int) -> String {
        s.count <= n ? s : String(s.prefix(n - 1)) + "…"
    }
}
