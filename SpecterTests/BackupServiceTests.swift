import XCTest
@testable import Specter

final class BackupServiceTests: XCTestCase {
    var tempDir: URL!

    override func setUp() async throws {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func test_snapshotCreatesTimestampedFile() async throws {
        let cfg = tempDir.appendingPathComponent("config")
        try "theme = Mocha".write(to: cfg, atomically: true, encoding: .utf8)
        let backups = tempDir.appendingPathComponent("backups")
        let svc = BackupService(configURL: cfg, backupDir: backups)
        let backup = try await svc.snapshot()
        XCTAssertNotNil(backup)
        let content = try String(contentsOf: backup!, encoding: .utf8)
        XCTAssertEqual(content, "theme = Mocha")
        XCTAssertTrue(backup!.path.contains(backups.path))
    }

    func test_snapshotMissingSource_returnsNil() async throws {
        let cfg = tempDir.appendingPathComponent("missing")
        let backups = tempDir.appendingPathComponent("backups")
        let svc = BackupService(configURL: cfg, backupDir: backups)
        let r = try await svc.snapshot()
        XCTAssertNil(r)
    }

    func test_pruneTo3() async throws {
        let cfg = tempDir.appendingPathComponent("config")
        try "x".write(to: cfg, atomically: true, encoding: .utf8)
        let backups = tempDir.appendingPathComponent("backups")
        let svc = BackupService(configURL: cfg, backupDir: backups, maxBackups: 3)
        for _ in 0..<5 {
            _ = try await svc.snapshot()
            try await Task.sleep(nanoseconds: 5_000_000)
        }
        let count = try FileManager.default.contentsOfDirectory(atPath: backups.path).count
        XCTAssertEqual(count, 3)
    }
}
