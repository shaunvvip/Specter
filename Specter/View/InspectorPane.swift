import SwiftUI

struct InspectorPane: View {
    @Environment(AppEnvironment.self) private var env
    let category: SettingCategory
    let searchQuery: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                if !env.configModel.dirtyKeys.isEmpty {
                    dirtyBadge.padding(.bottom, 8)
                }
                if let err = env.applyError {
                    errorBanner(err).padding(.bottom, 8)
                }
                ForEach(filteredEntries) { entry in
                    rowView(for: entry)
                    Divider().opacity(0.3)
                }
                if filteredEntries.isEmpty {
                    Text("没有匹配项")
                        .foregroundStyle(.secondary)
                        .padding(.top, 40).frame(maxWidth: .infinity)
                }
            }
            .padding(16)
        }
    }

    private var filteredEntries: [OptionEntry] {
        if searchQuery.isEmpty {
            return env.registry.entries.filter { $0.category == category && $0.isCurated }
        }
        return env.registry.search(searchQuery)
    }

    private var dirtyBadge: some View {
        HStack {
            Image(systemName: "circle.fill").foregroundStyle(.orange).font(.caption2)
            Text("\(env.configModel.dirtyKeys.count) 项未保存").font(.caption).foregroundStyle(.secondary)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
            Text(message).font(.callout)
        }
        .padding(8)
        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
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
