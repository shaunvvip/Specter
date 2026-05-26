import SwiftUI

struct CommandPalette: View {
    @Environment(AppEnvironment.self) private var env
    @Binding var isPresented: Bool
    @State private var query: String = ""
    let onSelect: (OptionEntry) -> Void

    private var results: [OptionEntry] {
        let hits = env.registry.search(query)
        return Array(hits.prefix(40))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("搜索所有 \(env.registry.entries.count) 项设置", text: $query)
                    .textFieldStyle(.plain)
                    .font(.title3)
            }
            .padding(14)
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(results) { entry in
                        Button(action: { commit(entry) }) {
                            row(for: entry)
                        }
                        .buttonStyle(.plain)
                        Divider().opacity(0.2)
                    }
                    if results.isEmpty {
                        Text("没有匹配项").foregroundStyle(.secondary).padding(40)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(maxHeight: 360)
        }
        .frame(width: 560, height: 420)
        .onExitCommand { isPresented = false }
    }

    private func row(for entry: OptionEntry) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(entry.key).font(.system(.body, design: .monospaced))
                Spacer()
                Text(entry.category.displayName).font(.caption).foregroundStyle(.secondary)
            }
            Text(entry.docMarkdown).font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private func commit(_ entry: OptionEntry) {
        onSelect(entry)
        isPresented = false
    }
}
