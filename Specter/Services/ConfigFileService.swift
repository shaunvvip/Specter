import Foundation

actor ConfigFileService {
    let configURL: URL

    init(configURL: URL) {
        self.configURL = configURL
    }

    func read() throws -> ParsedConfig {
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            return .empty
        }
        let content = try String(contentsOf: configURL, encoding: .utf8)
        let tokens = ConfigTokenizer.tokenize(content)
        let attrs = try FileManager.default.attributesOfItem(atPath: configURL.path)
        let mtime = (attrs[.modificationDate] as? Date) ?? .distantPast

        var values: [String: ConfigValue] = [:]
        for case .entry(let key, let raw, _) in tokens {
            values[key] = .string(raw)
        }
        return ParsedConfig(tokens: tokens, values: values, mtime: mtime)
    }

    /// `originalTokens` come from `read()`; pass them through so the writer can patch in-place
    /// while preserving comments / blanks / unknown keys byte-for-byte.
    ///
    /// **Critical**: only pass `dirtyValues` — keys the user actually edited. Passing the full
    /// values dict caused a data-loss bug where any key appearing multiple times in the original
    /// (e.g. multiple `keybind = ...` lines) got *every* occurrence rewritten with the last-seen
    /// value. By restricting to dirty keys, unedited multi-value keys pass through byte-identical.
    func write(dirtyValues: [String: ConfigValue], originalTokens: [ConfigToken]) throws {
        let originalKeys = Set(originalTokens.compactMap { token -> String? in
            if case .entry(let k, _, _) = token { return k } else { return nil }
        })

        var patches: [String: ConfigValue] = [:]
        var appending: [String: ConfigValue] = [:]
        for (key, val) in dirtyValues {
            if originalKeys.contains(key) {
                patches[key] = val
            } else {
                appending[key] = val
            }
        }

        let output = ConfigTokenizer.serialize(originalTokens, patching: patches, appending: appending)

        // Ensure parent dir exists
        let parent = configURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)

        // Atomic write: temp → fsync → rename
        let tempURL = configURL.appendingPathExtension("tmp")
        try output.write(to: tempURL, atomically: false, encoding: .utf8)
        let fh = try FileHandle(forUpdating: tempURL)
        try fh.synchronize()
        try fh.close()
        if FileManager.default.fileExists(atPath: configURL.path) {
            _ = try FileManager.default.replaceItemAt(configURL, withItemAt: tempURL)
        } else {
            try FileManager.default.moveItem(at: tempURL, to: configURL)
        }
    }
}
