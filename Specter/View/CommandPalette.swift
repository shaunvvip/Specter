import SwiftUI

/// ⌘K command palette. Matches the `.palette` block in design/specter-high-fidelity.html.
/// Auto-focuses on appear; return commits the first result; esc dismisses.
struct CommandPalette: View {
    @Environment(AppEnvironment.self) private var env
    @Binding var isPresented: Bool
    @State private var query: String = ""
    @FocusState private var searchFocused: Bool
    let onSelect: (OptionEntry) -> Void

    private var results: [OptionEntry] {
        let hits = env.registry.search(query)
        return Array(hits.prefix(40))
    }

    var body: some View {
        VStack(spacing: 18) {
            searchBar
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 10) {
                    if results.isEmpty {
                        Text(query.isEmpty
                             ? "Start typing to search \(env.registry.entries.count) options"
                             : "No matches for \"\(query)\"")
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.muted)
                            .padding(40).frame(maxWidth: .infinity)
                    } else {
                        ForEach(results) { entry in
                            HoverButton {
                                commit(entry)
                            } label: { hovering in
                                resultRow(for: entry, hovering: hovering)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 380)
        }
        .padding(24)
        .frame(width: 560)
        .background(Palette.panel)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Palette.lineStrong, lineWidth: 1))
        .onExitCommand { isPresented = false }
        .onAppear { searchFocused = true }
    }

    private var searchBar: some View {
        HStack(spacing: 20) {
            Text("⌘K")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(Palette.cyan)
            ZStack(alignment: .leading) {
                if query.isEmpty {
                    Text("Search every option…")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(Palette.muted)
                }
                TextField("", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(Palette.text)
                    .focused($searchFocused)
                    .onSubmit { commitFirst() }
            }
            Spacer()
            Text("\(results.count) results")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(Color(hex: 0x8a94a6))
        }
        .padding(.horizontal, 18)
        .frame(height: 58)
        .background(RoundedRectangle(cornerRadius: 14).fill(Palette.panel2))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.cyan.opacity(0.22), lineWidth: 1))
    }

    private func resultRow(for entry: OptionEntry, hovering: Bool) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.key)
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundStyle(Palette.text)
                Text(entry.docMarkdown)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: 0x8995a8))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(entry.category.displayName)
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(hovering ? Palette.cyan : Color(hex: 0xa8b3c5))
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Capsule().fill(hovering ? Palette.cyan.opacity(0.12) : Palette.panel3))
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .frame(height: 76)
        .background(
            RoundedRectangle(cornerRadius: 13)
                .fill(hovering ? Color(hex: 0x182234) : Color(hex: 0x141820))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(hovering ? Palette.cyan.opacity(0.34) : Palette.line, lineWidth: 1)
        )
    }

    private func commitFirst() {
        if let first = results.first { commit(first) }
    }

    private func commit(_ entry: OptionEntry) {
        onSelect(entry)
        isPresented = false
    }
}
