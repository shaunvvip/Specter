import SwiftUI

struct ThemeRow: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        OptionRowEnvelope(entry: entry) {
            let current = env.configModel.string(for: entry.key)
            Menu {
                Button {
                    env.configModel.set(entry.key, .string(""))
                    Task { await env.reloadCurrentThemeColors() }
                } label: {
                    Label("(default)", systemImage: current.isEmpty ? "checkmark" : "")
                }
                Divider()
                ForEach(env.availableThemes, id: \.self) { name in
                    Button {
                        env.configModel.set(entry.key, .string(name))
                        Task { await env.reloadCurrentThemeColors() }
                    } label: {
                        Label(name, systemImage: name == current ? "checkmark" : "")
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
