import SwiftUI

struct FontRow: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        OptionRowEnvelope(entry: entry) {
            Picker("", selection: Binding(
                get: {
                    if case .string(let s) = env.configModel.values[entry.key] { return s }
                    return ""
                },
                set: { env.configModel.set(entry.key, .string($0)) }
            )) {
                Text("Browse \(env.availableFonts.count)").tag("")
                ForEach(env.availableFonts, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 160)
        }
    }
}
