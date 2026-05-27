import SwiftUI

struct ContentView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var selectedCategory: SettingCategory = .appearance
    @State private var searchQuery: String = ""
    @State private var showCommandPalette = false

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selectedCategory: $selectedCategory)
                .frame(width: Metric.sidebarWidth)

            Divider().background(Palette.line)

            workspaceColumn
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Palette.bg)

            Divider().background(Palette.line)

            InspectorPane(category: selectedCategory, searchQuery: $searchQuery)
                .frame(width: Metric.inspectorWidth)
        }
        .frame(minWidth: 1180, minHeight: 760)
        .background(Palette.bg)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                pathChip
            }
            ToolbarItemGroup(placement: .primaryAction) {
                searchButton
                resetButton
                applyButton
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
                .opacity(0).frame(width: 0, height: 0)
        )
    }

    // MARK: - Workspace column

    private var workspaceColumn: some View {
        VStack(alignment: .leading, spacing: 26) {
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
            UnsavedRail()
        }
        .padding(.horizontal, 38).padding(.vertical, 36)
    }

    // MARK: - Toolbar items

    private var pathChip: some View {
        Text("~/.config/ghostty/config")
            .font(FontSpec.monoSmall)
            .foregroundStyle(Color(hex: 0x748094))
            .padding(.leading, 4)
    }

    private var searchButton: some View {
        Button {
            showCommandPalette = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color(hex: 0x738197))
                Text("Search every option")
                    .foregroundStyle(Color(hex: 0x738197))
                    .font(.system(size: 12))
                Text("⌘K")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Palette.muted)
                    .padding(.leading, 8)
            }
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(
                RoundedRectangle(cornerRadius: 8).fill(Color(hex: 0x10131a))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8).stroke(Palette.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .frame(minWidth: 220)
        .help("Open command palette (⌘K)")
    }

    private var resetButton: some View {
        Button {
            env.resetAll()
        } label: {
            Text("Reset")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: 0xd7deea))
                .padding(.horizontal, 13)
                .frame(height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 8).fill(Palette.panel3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8).stroke(Palette.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(env.configModel.dirtyKeys.isEmpty)
        .opacity(env.configModel.dirtyKeys.isEmpty ? 0.5 : 1)
    }

    private var applyButton: some View {
        Button {
            Task { await env.apply() }
        } label: {
            HStack(spacing: 6) {
                Text("Apply")
                if !env.configModel.dirtyKeys.isEmpty {
                    Text("\(env.configModel.dirtyKeys.count)")
                        .font(.system(size: 11, weight: .heavy))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.white.opacity(0.25)))
                }
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(height: 30)
            .background(
                LinearGradient(colors: [Color(hex: 0x4fa5ff), Color(hex: 0x2868e6)],
                               startPoint: .top, endPoint: .bottom)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: Color(hex: 0x3c82f6).opacity(0.32), radius: 8)
        }
        .buttonStyle(.plain)
        .disabled(env.configModel.dirtyKeys.isEmpty || env.isApplying)
        .opacity(env.configModel.dirtyKeys.isEmpty ? 0.5 : 1)
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
        .background(
            RoundedRectangle(cornerRadius: 12).fill(Palette.panel2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12).stroke(Palette.yellow.opacity(0.35), lineWidth: 1)
        )
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
        .background(
            RoundedRectangle(cornerRadius: 12).fill(Palette.red.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12).stroke(Palette.red.opacity(0.35), lineWidth: 1)
        )
    }
}
