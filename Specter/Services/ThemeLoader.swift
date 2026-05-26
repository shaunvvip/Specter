import Foundation

/// Reads and parses Ghostty theme files into XtermTheme structs.
///
/// Ghostty theme files use the same `key = value` format as the main config:
/// ```
/// palette = 0=#1e1e2e
/// palette = 1=#f38ba8
/// ...
/// background = #1e1e2e
/// foreground = #cdd6f4
/// cursor-color = #f5e0dc
/// ```
///
/// Resolves theme files from these search paths, in order:
///   1. `<ghostty-app-bundle>/Contents/Resources/ghostty/themes/<name>`
///   2. `/opt/homebrew/share/ghostty/themes/<name>`  (Homebrew Apple Silicon)
///   3. `/usr/local/share/ghostty/themes/<name>`     (Homebrew Intel)
///   4. `~/.config/ghostty/themes/<name>`            (user-installed)
actor ThemeLoader {
    private var cache: [String: XtermTheme] = [:]
    let ghostyBinaryURL: URL

    init(ghostyBinaryURL: URL) {
        self.ghostyBinaryURL = ghostyBinaryURL
    }

    func load(_ themeName: String) async -> XtermTheme? {
        guard !themeName.isEmpty else { return nil }
        if let cached = cache[themeName] { return cached }

        for candidate in searchPaths(for: themeName) {
            if let theme = try? parse(at: candidate) {
                cache[themeName] = theme
                return theme
            }
        }
        return nil
    }

    private func searchPaths(for name: String) -> [URL] {
        var paths: [URL] = []
        // 1. The active Ghostty binary's own bundle Resources/ghostty/themes/
        if ghostyBinaryURL.path.contains(".app/Contents/MacOS/") {
            // /Applications/Ghostty.app/Contents/MacOS/ghostty
            //   → ../../Resources/ghostty/themes/<name>
            let resources = ghostyBinaryURL
                .deletingLastPathComponent()  // MacOS/
                .deletingLastPathComponent()  // Contents/
                .appendingPathComponent("Resources/ghostty/themes", isDirectory: true)
            paths.append(resources.appendingPathComponent(name))
        }
        // 2 & 3. Homebrew layouts: <prefix>/share/ghostty/themes/<name>
        paths.append(URL(fileURLWithPath: "/opt/homebrew/share/ghostty/themes/\(name)"))
        paths.append(URL(fileURLWithPath: "/usr/local/share/ghostty/themes/\(name)"))
        // 4. User-installed themes
        let userThemes = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/ghostty/themes", isDirectory: true)
        paths.append(userThemes.appendingPathComponent(name))
        return paths
    }

    private func parse(at url: URL) throws -> XtermTheme {
        let content = try String(contentsOf: url, encoding: .utf8)
        return Self.parseThemeFile(content)
    }

    /// Pure parser (testable without filesystem). Falls back to Mocha colors for missing fields.
    static func parseThemeFile(_ content: String) -> XtermTheme {
        var palette: [Int: String] = [:]
        var background = "#1e1e2e"
        var foreground = "#cdd6f4"
        var cursor = "#f5e0dc"

        for line in content.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            guard let eq = trimmed.firstIndex(of: "=") else { continue }
            let key = String(trimmed[..<eq]).trimmingCharacters(in: .whitespaces)
            let value = String(trimmed[trimmed.index(after: eq)...]).trimmingCharacters(in: .whitespaces)

            switch key {
            case "background":     background = normalizeHex(value)
            case "foreground":     foreground = normalizeHex(value)
            case "cursor-color":   cursor = normalizeHex(value)
            case "palette":
                // value looks like "0=#1e1e2e" or "0=1e1e2e"
                if let eq2 = value.firstIndex(of: "=") {
                    let idx = Int(String(value[..<eq2]).trimmingCharacters(in: .whitespaces)) ?? -1
                    let color = normalizeHex(String(value[value.index(after: eq2)...]).trimmingCharacters(in: .whitespaces))
                    if (0...15).contains(idx) { palette[idx] = color }
                }
            default:
                break
            }
        }

        return XtermTheme(
            background: background, foreground: foreground, cursor: cursor,
            black:        palette[0]  ?? "#45475a",
            red:          palette[1]  ?? "#f38ba8",
            green:        palette[2]  ?? "#a6e3a1",
            yellow:       palette[3]  ?? "#f9e2af",
            blue:         palette[4]  ?? "#89b4fa",
            magenta:      palette[5]  ?? "#f5c2e7",
            cyan:         palette[6]  ?? "#94e2d5",
            white:        palette[7]  ?? "#bac2de",
            brightBlack:  palette[8]  ?? "#585b70",
            brightRed:    palette[9]  ?? "#f38ba8",
            brightGreen:  palette[10] ?? "#a6e3a1",
            brightYellow: palette[11] ?? "#f9e2af",
            brightBlue:   palette[12] ?? "#89b4fa",
            brightMagenta:palette[13] ?? "#f5c2e7",
            brightCyan:   palette[14] ?? "#94e2d5",
            brightWhite:  palette[15] ?? "#a6adc8"
        )
    }

    private static func normalizeHex(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("#") ? trimmed : "#\(trimmed)"
    }
}
