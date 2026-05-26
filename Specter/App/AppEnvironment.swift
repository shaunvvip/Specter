import Foundation
import Observation

@MainActor
@Observable
final class AppEnvironment {
    let configFileService: ConfigFileService
    let backupService: BackupService
    let ghostyCLI: GhostyCLI
    let reloadHelper: ReloadHelper

    var registry: OptionRegistry = OptionRegistry(entries: [], curated: [])
    var configModel: ConfigModel = ConfigModel(initialValues: [:])
    private var lastReadTokens: [ConfigToken] = []

    var loadError: String?
    var applyError: String?
    var lastReloadResult: ReloadResult?
    var isApplying: Bool = false

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
        let bin = ghostyBinary
            ?? GhostyCLI.resolvedBinary()
            ?? URL(fileURLWithPath: "/opt/homebrew/bin/ghostty")
        self.ghostyCLI = GhostyCLI(binaryURL: bin)
        self.reloadHelper = ReloadHelper()
    }

    func bootstrap() async {
        registry = OptionRegistry.curatedV1()
        do {
            let parsed = try await configFileService.read()
            self.configModel = ConfigModel(initialValues: parsed.values)
            self.lastReadTokens = parsed.tokens
        } catch {
            self.loadError = "Failed to read config: \(error.localizedDescription)"
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
            let valuesSnapshot = configModel.values   // Sendable (dict of ConfigValue)
            try await configFileService.write(values: valuesSnapshot, originalTokens: parsed.tokens)
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
