import Foundation
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

    var loadError: String?
    var applyError: String?
    var lastReloadResult: ReloadResult?
    var isApplying: Bool = false
    var ghostyBinaryFound: Bool = false
    // Eagerly-loaded so theme/font Pickers don't pop empty on first open.
    var availableThemes: [String] = []
    var availableFonts: [String] = []
    // Live theme colors for the current `theme` value, used by PreviewBridge.
    var currentThemeColors: XtermTheme = .mocha

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
    }

    /// Re-read the theme file matching `configModel.values["theme"]` and update
    /// `currentThemeColors` so PreviewPane redraws with the right palette.
    /// Call this on bootstrap, and whenever `theme` changes.
    func reloadCurrentThemeColors() async {
        let rawTheme: String
        if case .string(let s) = configModel.values["theme"] { rawTheme = s } else { rawTheme = "" }
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
    }
}
