import Foundation
import Combine
import Observation

@MainActor
@Observable
final class AppEnvironment {
    let configFileService: ConfigFileService
    let backupService: BackupService
    let ghostyCLI: GhostyCLI
    let reloadHelper: ReloadHelper
    let themeLoader: ThemeLoader

    var registry: OptionRegistry = OptionRegistry(entries: [], curated: [])
    var configModel: ConfigModel = ConfigModel(initialValues: [:])
    private var lastReadTokens: [ConfigToken] = []
    private var lastReadMtime: Date = .distantPast
    private var fileWatcher: FileWatcher?
    private var watcherSubscription: AnyCancellable?

    var loadError: String?
    var applyError: String?
    var lastReloadResult: ReloadResult?
    var isApplying: Bool = false
    var ghostyBinaryFound: Bool = false
    /// True when FileWatcher detected an external edit to ~/.config/ghostty/config
    /// after our last read. UI surfaces a banner offering to reload.
    var externalChangeDetected: Bool = false
    // Eagerly-loaded so theme/font Pickers don't pop empty on first open.
    var availableThemes: [String] = []
    var availableFonts: [String] = []
    // Live theme colors for the current `theme` value, used by PreviewBridge.
    var currentThemeColors: XtermTheme = .mocha

    private let configURL: URL

    static var defaultConfigURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/ghostty/config")
    }

    static var defaultBackupDir: URL {
        let appSupport = try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true
        )
        return (appSupport ?? FileManager.default.temporaryDirectory)
            .appendingPathComponent("Specter/Backups", isDirectory: true)
    }

    init(configURL: URL = AppEnvironment.defaultConfigURL,
         backupDir: URL = AppEnvironment.defaultBackupDir,
         ghostyBinary: URL? = nil) {
        self.configURL = configURL
        self.configFileService = ConfigFileService(configURL: configURL)
        self.backupService = BackupService(configURL: configURL, backupDir: backupDir)
        let resolved = ghostyBinary ?? GhostyCLI.resolvedBinary()
        let bin = resolved ?? URL(fileURLWithPath: "/opt/homebrew/bin/ghostty")
        self.ghostyCLI = GhostyCLI(binaryURL: bin)
        self.reloadHelper = ReloadHelper()
        self.themeLoader = ThemeLoader(ghostyBinaryURL: bin)
    }

    func bootstrap() async {
        registry = OptionRegistry.curatedV1()
        self.ghostyBinaryFound = GhostyCLI.resolvedBinary() != nil
        do {
            let parsed = try await configFileService.read()
            self.configModel = ConfigModel(initialValues: parsed.values)
            self.lastReadTokens = parsed.tokens
            self.lastReadMtime = parsed.mtime
        } catch {
            self.loadError = "Failed to read config: \(error.localizedDescription)"
        }
        // Eagerly populate Picker data so users don't see empty dropdowns.
        if ghostyBinaryFound {
            async let themes = (try? await ghostyCLI.listThemes()) ?? []
            async let fonts = (try? await ghostyCLI.listFonts()) ?? []
            let (t, f) = await (themes, fonts)
            self.availableThemes = t
            self.availableFonts = f
        }
        await reloadCurrentThemeColors()
        startWatchingConfigFile()
    }

    /// Re-read the theme file matching `configModel.values["theme"]` and update
    /// `currentThemeColors` so PreviewPane redraws with the right palette.
    /// Call this on bootstrap, on theme change, and on reset.
    func reloadCurrentThemeColors() async {
        let rawTheme = configModel.string(for: "theme")
        let themeName = PreviewBridge.parseThemeName(rawTheme)
        if let loaded = await themeLoader.load(themeName) {
            self.currentThemeColors = loaded
        } else {
            self.currentThemeColors = .mocha
        }
    }

    func apply() async {
        self.isApplying = true
        self.applyError = nil
        defer { self.isApplying = false }

        do {
            _ = try await backupService.snapshot()
        } catch {
            self.applyError = "Backup failed: \(error.localizedDescription) — refusing to apply"
            return
        }
        do {
            let parsed = try await configFileService.read()
            // Only write the keys the user actually edited. Passing the whole values dict caused
            // a data-loss bug for multi-value keys like `keybind` (Ghostty allows repeats).
            let dirtyKeys = configModel.dirtyKeys
            let dirtyValues = configModel.values.filter { dirtyKeys.contains($0.key) }
            try await configFileService.write(dirtyValues: dirtyValues, originalTokens: parsed.tokens)
            self.configModel.commit()
            self.lastReadTokens = parsed.tokens
            self.lastReadMtime = (try? await configFileService.read().mtime) ?? Date()
            self.externalChangeDetected = false  // our write isn't an external change
        } catch {
            self.applyError = "Apply failed: \(error.localizedDescription)"
            return
        }
        self.lastReloadResult = await reloadHelper.requestReload()
    }

    func resetAll() {
        for key in configModel.dirtyKeys {
            configModel.reset(key)
        }
        // Theme value may have reverted — refresh preview colors.
        Task { await reloadCurrentThemeColors() }
    }

    /// Re-read the config from disk after an external change. Discards any
    /// unsaved edits — caller should confirm.
    func reloadFromDisk() async {
        do {
            let parsed = try await configFileService.read()
            self.configModel = ConfigModel(initialValues: parsed.values)
            self.lastReadTokens = parsed.tokens
            self.lastReadMtime = parsed.mtime
            self.externalChangeDetected = false
            await reloadCurrentThemeColors()
        } catch {
            self.loadError = "Reload failed: \(error.localizedDescription)"
        }
    }

    // MARK: - External change detection

    private func startWatchingConfigFile() {
        guard FileManager.default.fileExists(atPath: configURL.path),
              let watcher = FileWatcher(url: configURL) else { return }
        self.fileWatcher = watcher
        self.watcherSubscription = watcher.changeSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                Task { @MainActor [weak self] in
                    await self?.onConfigFileChangedExternally()
                }
            }
    }

    private func onConfigFileChangedExternally() async {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: configURL.path),
              let mtime = attrs[.modificationDate] as? Date else { return }
        // If our most recent write set lastReadMtime, ignore that event.
        guard mtime > lastReadMtime else { return }
        self.externalChangeDetected = true
    }
}
