import SwiftUI

struct StringRow: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env

    private var defaultStr: String {
        if case .string(let s) = entry.defaultValue { return s }
        return ""
    }

    var body: some View {
        OptionRowEnvelope(entry: entry) {
            TextField("", text: Binding(
                get: { env.configModel.string(for: entry.key, default: defaultStr) },
                set: { env.configModel.set(entry.key, .string($0)) }
            ))
            .textFieldStyle(.roundedBorder)
            .frame(width: 110)
            .controlSize(.small)
        }
    }
}
