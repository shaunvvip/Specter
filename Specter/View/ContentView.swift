import SwiftUI

struct ContentView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var selectedCategory: SettingCategory = .appearance
    @State private var searchQuery: String = ""
    @State private var showCommandPalette = false
    @State private var showApplySheet = false
    /// Used by CommandPalette → Inspector to scroll a freshly-picked entry into view
    /// and flash-highlight it for ~1.5s.
    @State private var flashedKey: String?

    var body: some View {
        VStack(spacing: 0) {
            TitleBar(
                showCommandPalette: $showCommandPalette,
                showApplySheet: $showApplySheet,
                onResetClearsSearch: { searchQuery = "" }
            )
            if env.externalChangeDetected {
                externalChangeBanner
            }
            HStack(spacing: 0) {
                SidebarView(selectedCategory: $selectedCategory)
                    .frame(width: Metric.sidebarWidth)

                Rectangle().fill(Palette.line).frame(width: 1)

                workspaceColumn
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Palette.bg)

                Rectangle().fill(Palette.line).frame(width: 1)

                InspectorPane(
                    category: selectedCategory,
                    searchQuery: $searchQuery,
                    flashedKey: $flashedKey
                )
                .frame(width: Metric.inspectorWidth)
            }
        }
        .frame(minWidth: 1180, minHeight: 760)
        .background(Palette.bg)
        .sheet(isPresented: $showCommandPalette) {
            CommandPalette(isPresented: $showCommandPalette) { entry in
                selectedCategory = entry.category
                searchQuery = ""
                flashedKey = entry.key
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

            ThemeStrip(onOpenAllThemes: {
                showCommandPalette = true
            })
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

    /// Banner shown at top of window when FileWatcher detects an external edit
    /// to ~/.config/ghostty/config (e.g. user edits it in vim). Sits above the
    /// 3-column shell so the dirty state stays visible while user decides.
    private var externalChangeBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundStyle(Palette.cyan)
            VStack(alignment: .leading, spacing: 2) {
                Text("Config changed outside Specter")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.text)
                Text("Disk has updates the editor doesn't know about.")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.muted)
            }
            Spacer()
            if !env.configModel.dirtyKeys.isEmpty {
                Text("\(env.configModel.dirtyKeys.count) unsaved")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(Palette.yellow)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(Palette.yellow.opacity(0.12)))
            }
            Button("Reload & discard edits") {
                Task { await env.reloadFromDisk() }
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 12).frame(height: 28)
            .background(RoundedRectangle(cornerRadius: 7).fill(Palette.blue))
            Button("Dismiss") { env.externalChangeDetected = false }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(Palette.muted)
        }
        .padding(.horizontal, 18).padding(.vertical, 10)
        .background(Palette.panel2)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(Palette.cyan.opacity(0.35)), alignment: .bottom)
    }
}
