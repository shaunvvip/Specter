import SwiftUI

struct SidebarView: View {
    @Binding var selectedCategory: SettingCategory

    private let categoriesInOrder: [SettingCategory] = [
        .appearance, .font, .window, .cursor, .mouse,
        .shellIntegration, .keybind, .macos, .advanced
    ]

    var body: some View {
        List(selection: $selectedCategory) {
            ForEach(categoriesInOrder) { cat in
                Label(cat.displayName, systemImage: cat.sfSymbol).tag(cat)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Specter")
    }
}
