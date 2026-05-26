import SwiftUI

struct InspectorPane: View {
    @Environment(AppEnvironment.self) private var env
    let category: SettingCategory
    @Binding var searchQuery: String

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredEntries) { entry in
                        rowView(for: entry)
                        Divider().opacity(0.25)
                    }
                    if filteredEntries.isEmpty {
                        Text(searchQuery.isEmpty ? "本分类暂无 curated 选项" : "没有匹配 \"\(searchQuery)\"")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                            .padding(.top, 40).frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: searchQuery.isEmpty ? category.sfSymbol : "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                Text(searchQuery.isEmpty ? category.displayName : "搜索结果")
                    .font(.headline)
                Spacer()
                statusChip
            }
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                TextField("在本分类内过滤…", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.callout)
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8).padding(.vertical, 5)
            .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
        }
        .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 10)
        .background(.bar)
    }

    @ViewBuilder
    private var statusChip: some View {
        let count = env.configModel.dirtyKeys.count
        if count > 0 {
            HStack(spacing: 4) {
                Circle().frame(width: 6, height: 6).foregroundStyle(.orange)
                Text("\(count) 项未保存").font(.caption).foregroundStyle(.secondary)
            }
        } else {
            Text("\(filteredEntries.count) 项").font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: - Data

    private var filteredEntries: [OptionEntry] {
        if searchQuery.isEmpty {
            return env.registry.entries.filter { $0.category == category && $0.isCurated }
        }
        return env.registry.search(searchQuery)
    }

    @ViewBuilder
    private func rowView(for entry: OptionEntry) -> some View {
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
}
