import SwiftUI

struct EnumRow: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env

    private var current: String {
        if case .string(let s) = env.configModel.values[entry.key] { return s }
        if case .string(let s) = entry.defaultValue { return s }
        return ""
    }

    var body: some View {
        OptionRowEnvelope(entry: entry) {
            if case .enumeration(let cases) = entry.type {
                Menu {
                    ForEach(cases, id: \.self) { c in
                        Button(c == current ? "✓ \(c)" : c) {
                            env.configModel.set(entry.key, .string(c))
                        }
                    }
                } label: {
                    ValueChip(
                        text: current,
                        isDirty: env.configModel.dirtyKeys.contains(entry.key)
                    )
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        }
    }
}
