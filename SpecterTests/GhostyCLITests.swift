import XCTest
@testable import Specter

final class GhostyCLITests: XCTestCase {
    var fakeBinary: URL!

    override func setUp() async throws {
        let bundle = Bundle(for: type(of: self))
        guard let path = bundle.path(forResource: "fake-ghostty", ofType: "sh") else {
            XCTFail("Missing fixture fake-ghostty.sh — make sure it's in SpecterTests/Fixtures/")
            return
        }
        // Copy to writable temp + chmod +x; original in bundle may be read-only
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("fake-ghostty-\(UUID().uuidString).sh")
        try FileManager.default.copyItem(at: URL(fileURLWithPath: path), to: tmp)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tmp.path)
        fakeBinary = tmp
    }

    override func tearDown() async throws {
        if let u = fakeBinary { try? FileManager.default.removeItem(at: u) }
    }

    func test_listThemes() async throws {
        let cli = GhostyCLI(binaryURL: fakeBinary)
        let themes = try await cli.listThemes()
        XCTAssertTrue(themes.contains("TokyoNight Storm"))
        XCTAssertTrue(themes.contains("Catppuccin Mocha"))
        XCTAssertEqual(themes.count, 5)
    }

    func test_listFonts() async throws {
        let cli = GhostyCLI(binaryURL: fakeBinary)
        let fonts = try await cli.listFonts()
        XCTAssertTrue(fonts.contains("JetBrains Mono"))
    }

    func test_version() async throws {
        let cli = GhostyCLI(binaryURL: fakeBinary)
        let v = try await cli.version()
        XCTAssertEqual(v, "Ghostty 1.0.0")
    }

    func test_binaryMissing_throws() async {
        let cli = GhostyCLI(binaryURL: URL(fileURLWithPath: "/nonexistent/ghostty"))
        do {
            _ = try await cli.listThemes()
            XCTFail("Expected throw")
        } catch GhostyCLIError.binaryNotFound {
            // ok
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_cachingReusesResult() async throws {
        let cli = GhostyCLI(binaryURL: fakeBinary)
        let first = try await cli.listThemes()
        let second = try await cli.listThemes()
        XCTAssertEqual(first, second)
    }
}
