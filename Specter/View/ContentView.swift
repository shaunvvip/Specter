import SwiftUI

struct ContentView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var selectedCategory: SettingCategory = .appearance
    @State private var searchQuery: String = ""
    @State private var showCommandPalette = false
    @State private var showApplySheet = false

    var body: some View {
        VStack(spacing: 0) {
            TitleBar(showCommandPalette: $showCommandPalette, showApplySheet: $showApplySheet)
            HStack(spacing: 0) {
                SidebarView(selectedCategory: $selectedCategory)
                    .frame(width: Metric.sidebarWidth)

                Rectangle().fill(Palette.line).frame(width: 1)

                workspaceColumn
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Palette.bg)

                Rectangle().fill(Palette.line).frame(width: 1)

                InspectorPane(category: selectedCategory, searchQuery: $searchQuery)
                    .frame(width: Metric.inspectorWidth)
            }
        }
        .frame(minWidth: 1180, minHeight: 760)
        .background(Palette.bg)
        .sheet(isPresented: $showCommandPalette) {
            CommandPalette(isPresented: $showCommandPalette) { entry in
                selectedCategory = entry.category
                searchQuery = entry.key
            }
        }
        .sheet(isPresented: $showApplySheet) {
            ApplyConfirmationSheet(isPresented: $showApplySheet)
        }
        .background(
            Button("") { showCommandPalette = true }
                .keyboardShortcut("k", modifiers: .command)
                .opacity(0).frame(width: 0, height: 0)
        )
    }

    // MARK: - Workspace column

    private var workspaceColumn: some View {
        VStack(alignment: .leading, spacing: 22) {
            if !env.ghostyBinaryFound {
                binaryNotFoundBanner
            }
            if let err = env.applyError {
                applyErrorBanner(err)
            }

            WorkspaceHeader(
                eyebrow: "TERMINAL LAB",
                title: "Tune once. See it immediately.",
                subcopy: "Every control updates the embedded preview instantly. Disk stays untouched until Apply."
            )

            ThemeStrip()
            PreviewHalo()
                .frame(maxHeight: .infinity)
            UnsavedRail(showApplySheet: $showApplySheet)
        }
        .padding(.horizontal, 38).padding(.vertical, 32)
    }

    // MARK: - Banners

    private var binaryNotFoundBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Palette.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("Ghostty not found").font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.text)
                Text("Searched /Applications/Ghostty.app and Homebrew paths. Install Ghostty then relaunch Specter.")
                    .font(.system(size: 12)).foregroundStyle(Palette.muted)
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Palette.panel2))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.yellow.opacity(0.35), lineWidth: 1))
    }

    private func applyErrorBanner(_ msg: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "xmark.octagon.fill").foregroundStyle(Palette.red)
            Text(msg).font(.system(size: 13)).foregroundStyle(Palette.text)
            Spacer()
            Button("Dismiss") { env.applyError = nil }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.muted)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Palette.red.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.red.opacity(0.35), lineWidth: 1))
    }
}
