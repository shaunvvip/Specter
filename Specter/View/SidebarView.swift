import SwiftUI

struct SidebarView: View {
    @Environment(AppEnvironment.self) private var env
    @Binding var selectedCategory: SettingCategory

    /// Canonical category order. Only categories with at least one curated entry
    /// in the registry appear in the sidebar — avoids showing dead nav rows.
    private let categoryOrder: [SettingCategory] = [
        .appearance, .font, .window, .cursor, .mouse,
        .shellIntegration, .keybind, .macos, .advanced
    ]

    private var visibleCategories: [SettingCategory] {
        let populated = Set(env.registry.curatedEntries.map(\.category))
        return categoryOrder.filter { populated.contains($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("CONFIG AREAS")
                .font(FontSpec.label)
                .tracking(1)
                .foregroundStyle(Palette.dim)
                .padding(.leading, 14).padding(.top, 24).padding(.bottom, 14)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(visibleCategories) { cat in
                        navRow(cat)
                    }
                }
                .padding(.horizontal, 8)
            }

            Spacer(minLength: 0)
            safetyCard.padding(8)
        }
        .frame(maxHeight: .infinity)
        .background(Palette.sidebarBg)
        .onAppear {
            // If the previously-selected category is no longer populated
            // (e.g. registry data changed), drop selection to the first one.
            if !visibleCategories.contains(selectedCategory),
               let first = visibleCategories.first {
                selectedCategory = first
            }
        }
    }

    private func navRow(_ cat: SettingCategory) -> some View {
        let isActive = cat == selectedCategory
        return Button {
            selectedCategory = cat
        } label: {
            HStack(spacing: 12) {
                Text(cat.glyph)
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(isActive ? Color.white : Palette.muted)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(isActive ? Palette.blue.opacity(0.95) : Color(hex: 0x2a303b))
                    )
                    .shadow(color: isActive ? Palette.blueHi.opacity(0.32) : .clear, radius: 8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(cat.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isActive ? Palette.text : Palette.soft)
                    Text(cat.sidebarSubtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: 0x778399))
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive
                          ? AnyShapeStyle(LinearGradient(
                              colors: [Color(hex: 0x2e76be).opacity(0.34), Color(hex: 0x2f455f).opacity(0.18)],
                              startPoint: .leading, endPoint: .trailing))
                          : AnyShapeStyle(Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? Palette.blueHi.opacity(0.24) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var safetyCard: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Safe write model")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.text)
            Text("Backs up first. Writes only dirty keys. Keeps comments and unknown config lines intact.")
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: 0x8995a8))
                .lineSpacing(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: 0x151922)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.line, lineWidth: 1))
    }
}
