import SwiftUI

struct FontRow: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env
    @State private var expanded = false
    @State private var fonts: [String] = []

    var body: some View {
        OptionRowEnvelope(entry: entry, isExpanded: $expanded) {
            Picker("", selection: Binding(
                get: {
                    if case .string(let s) = env.configModel.values[entry.key] { return s }
                    return ""
                },
                set: { env.configModel.set(entry.key, .string($0)) }
            )) {
                Text("(default)").tag("")
                ForEach(fonts, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
        .task {
            let result: [String]
            do {
                result = try await env.ghostyCLI.listFonts()
            } catch {
                result = []
            }
            fonts = result
        }
    }
}
