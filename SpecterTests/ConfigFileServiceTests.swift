import XCTest
@testable import Specter

final class ConfigFileServiceTests: XCTestCase {
    var tempDir: URL!

    override func setUp() async throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    private func writeFixture(_ name: String, _ content: String) throws -> URL {
        let url = tempDir.appendingPathComponent(name)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func test_readMissingFile_returnsEmpty() async throws {
        let svc = ConfigFileService(configURL: tempDir.appendingPathComponent("nonexistent"))
        let parsed = try await svc.read()
        XCTAssertEqual(parsed.tokens.count, 0)
        XCTAssertTrue(parsed.values.isEmpty)
    }

    func test_readBasicFile_extractsValues() async throws {
        let url = try writeFixture("config", "theme = Mocha\nfont-size = 14\n")
        let svc = ConfigFileService(configURL: url)
        let parsed = try await svc.read()
        XCTAssertEqual(parsed.values["theme"], .string("Mocha"))
        XCTAssertEqual(parsed.values["font-size"], .string("14"))
    }

    func test_writePreservesComments() async throws {
        let original = "# my heading\ntheme = Mocha\nfont-size = 14\n"
        let url = try writeFixture("config", original)
        let svc = ConfigFileService(configURL: url)

        let parsed = try await svc.read()
        let model = ConfigModel(initialValues: parsed.values)
        model.set("theme", .string("TokyoNight"))

        let dirty = model.values.filter { model.dirtyKeys.contains($0.key) }
        try await svc.write(dirtyValues: dirty, originalTokens: parsed.tokens)
        let after = try String(contentsOf: url, encoding: .utf8)

        XCTAssertTrue(after.contains("# my heading"))
        XCTAssertTrue(after.contains("theme = TokyoNight"))
        XCTAssertTrue(after.contains("font-size = 14"))
        XCTAssertFalse(after.contains("= Mocha"))
    }

    func test_writeAtomic_noTempLeftBehind() async throws {
        let url = try writeFixture("config", "theme = Mocha\n")
        let svc = ConfigFileService(configURL: url)
        let parsed = try await svc.read()
        let model = ConfigModel(initialValues: parsed.values)
        try await svc.write(dirtyValues: [:], originalTokens: parsed.tokens)
        let siblings = try FileManager.default.contentsOfDirectory(atPath: tempDir.path)
        XCTAssertFalse(siblings.contains(where: { $0.hasSuffix(".tmp") }))
    }

    func test_writeCreatesFileWhenMissing() async throws {
        let url = tempDir.appendingPathComponent("nested/dir/config")
        let svc = ConfigFileService(configURL: url)
        let model = ConfigModel(initialValues: [:])
        model.set("theme", .string("Mocha"))
        let dirty = model.values.filter { model.dirtyKeys.contains($0.key) }
        try await svc.write(dirtyValues: dirty, originalTokens: [])
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("theme = Mocha"))
        XCTAssertTrue(content.contains("# Added by Specter"))
    }

    /// Regression test for the keybind data-loss bug:
    /// Ghostty config allows the same key (e.g. `keybind = ...`) to appear multiple times.
    /// If the user doesn't edit any of those lines, write() must leave ALL of them byte-identical.
    func test_writePreservesDuplicateUneditedKeys() async throws {
        let original = """
        theme = Mocha
        keybind = super+q=close_window
        keybind = super+t=new_tab
        keybind = super+i=inspector:toggle
        font-size = 14
        """
        let url = try writeFixture("config", original)
        let svc = ConfigFileService(configURL: url)
        let parsed = try await svc.read()
        let model = ConfigModel(initialValues: parsed.values)
        model.set("theme", .string("TokyoNight"))   // user edits only `theme`

        let dirty = model.values.filter { model.dirtyKeys.contains($0.key) }
        try await svc.write(dirtyValues: dirty, originalTokens: parsed.tokens)
        let after = try String(contentsOf: url, encoding: .utf8)

        XCTAssertTrue(after.contains("keybind = super+q=close_window"))
        XCTAssertTrue(after.contains("keybind = super+t=new_tab"))
        XCTAssertTrue(after.contains("keybind = super+i=inspector:toggle"))
        XCTAssertTrue(after.contains("theme = TokyoNight"))
        XCTAssertFalse(after.contains("= Mocha"))
    }
}
