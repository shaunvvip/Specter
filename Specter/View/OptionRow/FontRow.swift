import SwiftUI

struct FontRow: View {
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
                }
                Divider()
                ForEach(env.availableFonts, id: \.self) { name in
                    Button(name == current ? "✓ \(name)" : name) {
                        env.configModel.set(entry.key, .string(name))
                    }
                }
            } label: {
                ValueChip(
                    text: current.isEmpty ? "Browse \(env.availableFonts.count)" : truncate(current, 14),
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
