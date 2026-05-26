import XCTest
@testable import Specter

final class ThemeLoaderTests: XCTestCase {
    func test_parsesDraculaExample() {
        // Verbatim sample from /Applications/Ghostty.app/Contents/Resources/ghostty/themes/Dracula
        let source = """
        palette = 0=#21222c
        palette = 1=#ff5555
        palette = 2=#50fa7b
        palette = 3=#f1fa8c
        palette = 4=#bd93f9
        palette = 5=#ff79c6
        palette = 6=#8be9fd
        palette = 7=#f8f8f2
        palette = 8=#6272a4
        palette = 9=#ff6e6e
        palette = 10=#69ff94
        palette = 11=#ffffa5
        palette = 12=#d6acff
        palette = 13=#ff92df
        palette = 14=#a4ffff
        palette = 15=#ffffff
        background = #282a36
        foreground = #f8f8f2
        cursor-color = #f8f8f2
        cursor-text = #282a36
        """
        let theme = ThemeLoader.parseThemeFile(source)
        XCTAssertEqual(theme.background, "#282a36")
        XCTAssertEqual(theme.foreground, "#f8f8f2")
        XCTAssertEqual(theme.cursor, "#f8f8f2")
        XCTAssertEqual(theme.red, "#ff5555")
        XCTAssertEqual(theme.brightWhite, "#ffffff")
    }

    func test_palettesWithoutHashPrefix() {
        // Some Ghostty themes write `palette = 0=1e1e2e` (no leading #).
        let source = """
        palette = 0=1e1e2e
        palette = 1=f38ba8
        background = 1e1e2e
        foreground = cdd6f4
        """
        let theme = ThemeLoader.parseThemeFile(source)
        XCTAssertEqual(theme.background, "#1e1e2e")
        XCTAssertEqual(theme.foreground, "#cdd6f4")
        XCTAssertEqual(theme.red, "#f38ba8")
    }

    func test_emptyFile_fallsBackToMochaDefaults() {
        let theme = ThemeLoader.parseThemeFile("")
        XCTAssertEqual(theme.background, "#1e1e2e")
        XCTAssertEqual(theme.foreground, "#cdd6f4")
    }

    func test_ignoresUnknownKeys() {
        let source = """
        cursor-text = #282a36
        some-future-key = whatever
        background = #abcdef
        """
        let theme = ThemeLoader.parseThemeFile(source)
        XCTAssertEqual(theme.background, "#abcdef")
    }
}
