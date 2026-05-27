import SwiftUI

struct InspectorPane: View {
    @Environment(AppEnvironment.self) private var env
    let category: SettingCategory
    @Binding var searchQuery: String
    @Binding var flashedKey: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(headerTitle)
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(Palette.inspectorText)
                Text(headerSubtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.inspectorMuted)
                    .lineSpacing(2)
            }
            .padding(.bottom, 18)

            StatusCard()
                .padding(.bottom, 6)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if filteredEntries.isEmpty {
                            emptyState
                        } else {
                            SectionLabel(title: sectionLabelText)
                            ForEach(filteredEntries) { entry in
                                rowView(for: entry)
                                    .id(entry.key)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onChange(of: flashedKey) { _, newValue in
                    guard let key = newValue else { return }
                    withAnimation {
                        proxy.scrollTo(key, anchor: .center)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        flashedKey = nil
                    }
                }
            }
        }
        .padding(.horizontal, 28).padding(.vertical, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.inspectorBg)
    }

    private var headerTitle: String {
        searchQuery.isEmpty ? category.displayName : "Search results"
    }

    private var headerSubtitle: String {
        searchQuery.isEmpty
            ? "Curated settings with docs, constraints, and suggested defaults."
            : "Matches across all \(env.registry.entries.count) Ghostty options."
    }

    private var sectionLabelText: String {
        if !searchQuery.isEmpty { return "MATCHES" }
        switch category {
        case .appearance: return "VISUAL"
        case .font: return "TYPOGRAPHY"
        default: return category.displayName.uppercased()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 24))
                .foregroundStyle(Palette.inspectorMuted)
            Text(searchQuery.isEmpty ? "No curated options here yet" : "No matches for \"\(searchQuery)\"")
                .font(.system(size: 13))
                .foregroundStyle(Palette.inspectorMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 56)
    }

    private var filteredEntries: [OptionEntry] {
        if searchQuery.isEmpty {
            return env.registry.entries.filter { $0.category == category && $0.isCurated }
        }
        return env.registry.search(searchQuery)
    }

    @ViewBuilder
    private func rowView(for entry: OptionEntry) -> some View {
        let isFlashed = flashedKey == entry.key
        Group {
            switch entry.type {
            case .bool:                          ToggleRow(entry: entry)
            case .integer, .double:              SliderRow(entry: entry)
            case .enumeration:                   EnumRow(entry: entry)
            case .theme:                         ThemeRow(entry: entry)
            case .font:                          FontRow(entry: entry)
            case .string, .color, .keybind, .opaque:
                                                 StringRow(entry: entry)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Palette.blueHi.opacity(isFlashed ? 0.9 : 0), lineWidth: 2)
                .animation(.easeOut(duration: 0.4), value: isFlashed)
        )
    }
}
