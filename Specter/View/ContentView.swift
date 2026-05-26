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
                if !env.ghostyBinaryFound {
                    binaryNotFoundBanner
                }
                if let err = env.applyError {
                    errorBanner(err)
                }
                PreviewPane()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } detail: {
            InspectorPane(category: selectedCategory, searchQuery: $searchQuery)
                .frame(minWidth: 320)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                applyButton
                resetButton
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCommandPalette = true
                } label: {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .help("⌘K  全文搜索 \(env.registry.entries.count) 项设置")
            }
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

    private var applyButton: some View {
        Button {
            Task { await env.apply() }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                Text("Apply")
                if !env.configModel.dirtyKeys.isEmpty {
                    Text("\(env.configModel.dirtyKeys.count)")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(Color.orange, in: Capsule())
                        .foregroundStyle(.white)
                }
            }
        }
        .disabled(env.configModel.dirtyKeys.isEmpty || env.isApplying)
        .help(env.configModel.dirtyKeys.isEmpty ? "没有改动" : "保存到 ~/.config/ghostty/config 并通知 Ghostty 重载")
    }

    private var resetButton: some View {
        Button {
            env.resetAll()
        } label: {
            Label("Reset", systemImage: "arrow.uturn.backward")
        }
        .disabled(env.configModel.dirtyKeys.isEmpty)
        .help("丢弃所有未保存改动")
    }

    private var binaryNotFoundBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Ghostty 未找到").font(.callout.weight(.medium))
                Text("已查找 /Applications/Ghostty.app 和 Homebrew 路径。装好后重启 Specter。")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.bar)
    }

    private func errorBanner(_ msg: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "xmark.octagon.fill").foregroundStyle(.red)
            Text(msg).font(.callout)
            Spacer()
            Button("Dismiss") { env.applyError = nil }.buttonStyle(.plain)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color.red.opacity(0.08))
    }
}
