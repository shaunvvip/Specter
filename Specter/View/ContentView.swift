import SwiftUI

struct ContentView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var selectedCategory: SettingCategory = .appearance
    @State private var searchQuery: String = ""
    @State private var showCommandPalette = false

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
        .sheet(isPresented: $showCommandPalette) {
            CommandPalette(isPresented: $showCommandPalette) { entry in
                selectedCategory = entry.category
                searchQuery = entry.key
            }
        }
        .background(
            Button("") { showCommandPalette = true }
                .keyboardShortcut("k", modifiers: .command)
                .opacity(0)
                .frame(width: 0, height: 0)
        )
    }
}
