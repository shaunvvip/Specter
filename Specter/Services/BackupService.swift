import Foundation

actor BackupService {
    let configURL: URL
    let backupDir: URL
    let maxBackups: Int

    init(configURL: URL, backupDir: URL, maxBackups: Int = 20) {
        self.configURL = configURL
        self.backupDir = backupDir
        self.maxBackups = maxBackups
    }

    @discardableResult
    func snapshot() throws -> URL? {
        guard FileManager.default.fileExists(atPath: configURL.path) else { return nil }
        try FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)

        let ts = Self.timestamp(Date())
        var dest = backupDir.appendingPathComponent("\(ts).config")
        // de-collide if same-millisecond
        var attempt = 0
        while FileManager.default.fileExists(atPath: dest.path) && attempt < 100 {
            attempt += 1
            dest = backupDir.appendingPathComponent("\(ts)-\(attempt).config")
        }
        try FileManager.default.copyItem(at: configURL, to: dest)
        try prune()
        return dest
    }

    private func prune() throws {
        let urls = try FileManager.default
            .contentsOfDirectory(at: backupDir, includingPropertiesForKeys: [.contentModificationDateKey])
            .filter { $0.pathExtension == "config" }
        guard urls.count > maxBackups else { return }
        let sorted = try urls.sorted { lhs, rhs in
            let l = try lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? .distantPast
            let r = try rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? .distantPast
            return l < r
        }
        for url in sorted.prefix(sorted.count - maxBackups) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    static func timestamp(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH-mm-ss-SSS"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: date)
    }
}
