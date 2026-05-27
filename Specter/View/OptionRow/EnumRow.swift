import SwiftUI

struct EnumRow: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env

    private var defaultStr: String {
        if case .string(let s) = entry.defaultValue { return s }
        return ""
    }

    var body: some View {
        OptionRowEnvelope(entry: entry) {
            if case .enumeration(let cases) = entry.type {
                let current = env.configModel.string(for: entry.key, default: defaultStr)
                Menu {
                    ForEach(cases, id: \.self) { c in
                        Button {
                            env.configModel.set(entry.key, .string(c))
                        } label: {
                            Label(c, systemImage: c == current ? "checkmark" : "")
                        }
                    }
                } label: {
                    ValueChip(
                        text: current.isEmpty ? "—" : current,
                        isDirty: env.configModel.dirtyKeys.contains(entry.key)
                    )
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        }
    }
}
