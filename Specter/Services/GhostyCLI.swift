import Foundation

enum GhostyCLIError: Error, Equatable {
    case binaryNotFound
    case nonZeroExit(Int32, stderr: String)
    case timeout
}

actor GhostyCLI {
    let binaryURL: URL
    let timeoutSeconds: TimeInterval

    private var cachedThemes: [String]?
    private var cachedFonts: [String]?

    init(binaryURL: URL, timeoutSeconds: TimeInterval = 3) {
        self.binaryURL = binaryURL
        self.timeoutSeconds = timeoutSeconds
    }

    static func resolvedBinary() -> URL? {
        let candidates = [
            "/Applications/Ghostty.app/Contents/MacOS/ghostty",     // official Mac app install
            "/opt/homebrew/bin/ghostty",                             // Homebrew (Apple Silicon)
            "/usr/local/bin/ghostty",                                // Homebrew (Intel)
        ]
        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }

    func listThemes() async throws -> [String] {
        if let cached = cachedThemes { return cached }
        let out = try run(["+list-themes"])
        let themes = out.split(separator: "\n").map {
            Self.stripSourceSuffix(String($0).trimmingCharacters(in: .whitespaces))
        }.filter { !$0.isEmpty }
        cachedThemes = themes
        return themes
    }

    func listFonts() async throws -> [String] {
        if let cached = cachedFonts { return cached }
        let out = try run(["+list-fonts"])
        let fonts = out.split(separator: "\n").map {
            Self.stripSourceSuffix(String($0).trimmingCharacters(in: .whitespaces))
        }.filter { !$0.isEmpty }
        cachedFonts = fonts
        return fonts
    }

    /// `ghostty +list-themes / +list-fonts` annotate items with a source suffix like
    /// `Catppuccin Mocha (resources)` or `MyCustomTheme (user)`. The annotation is not part
    /// of the theme/font name and would be invalid if written back into a config file.
    private static func stripSourceSuffix(_ s: String) -> String {
        if s.hasSuffix(" (resources)") {
            return String(s.dropLast(" (resources)".count))
        }
        if s.hasSuffix(" (user)") {
            return String(s.dropLast(" (user)".count))
        }
        return s
    }

    func version() async throws -> String {
        try run(["+version"]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func run(_ args: [String]) throws -> String {
        guard FileManager.default.isExecutableFile(atPath: binaryURL.path) else {
            throw GhostyCLIError.binaryNotFound
        }
        let process = Process()
        process.executableURL = binaryURL
        process.arguments = args
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        try process.run()

        let deadline = Date().addingTimeInterval(timeoutSeconds)
        while process.isRunning {
            if Date() > deadline {
                process.terminate()
                throw GhostyCLIError.timeout
            }
            Thread.sleep(forTimeInterval: 0.02)
        }

        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        if process.terminationStatus != 0 {
            throw GhostyCLIError.nonZeroExit(
                process.terminationStatus,
                stderr: String(data: errData, encoding: .utf8) ?? ""
            )
        }
        return String(data: outData, encoding: .utf8) ?? ""
    }
}
