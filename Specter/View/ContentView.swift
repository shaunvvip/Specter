import SwiftUI

struct ContentView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var selectedCategory: SettingCategory = .appearance
    @State private var searchQuery: String = ""

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedCategory: $selectedCategory)
                .frame(minWidth: 160)
        } content: {
            VStack(spacing: 0) {
                TopBar(searchQuery: $searchQuery)
                Divider()
                PreviewPane()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } detail: {
            InspectorPane(category: selectedCategory, searchQuery: searchQuery)
                .frame(minWidth: 320)
        }
    }
}
