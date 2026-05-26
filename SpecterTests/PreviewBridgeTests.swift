import XCTest
@testable import Specter

final class PreviewBridgeTests: XCTestCase {
    func test_defaultModel_defaultOptions() {
        let m = ConfigModel(initialValues: [:])
        let opts = PreviewBridge.translate(m)
        XCTAssertEqual(opts.fontSize, 14)
        XCTAssertEqual(opts.fontFamily, "JetBrains Mono")
        XCTAssertEqual(opts.cursorStyle, "block")
        XCTAssertEqual(opts.backgroundOpacity, 1.0, accuracy: 0.0001)
    }

    func test_fontSizeApplied() {
        let m = ConfigModel(initialValues: ["font-size": .integer(18)])
        XCTAssertEqual(PreviewBridge.translate(m).fontSize, 18)
    }

    func test_fontFamilyApplied() {
        let m = ConfigModel(initialValues: ["font-family": .string("Fira Code")])
        XCTAssertEqual(PreviewBridge.translate(m).fontFamily, "Fira Code")
    }

    func test_backgroundOpacityApplied() {
        let m = ConfigModel(initialValues: ["background-opacity": .double(0.7)])
        XCTAssertEqual(PreviewBridge.translate(m).backgroundOpacity, 0.7, accuracy: 0.0001)
    }

    func test_cursorStyleMappedToXterm() {
        let m = ConfigModel(initialValues: ["cursor-style": .string("bar")])
        XCTAssertEqual(PreviewBridge.translate(m).cursorStyle, "bar")
    }

    func test_paddingParsedFromString() {
        let m = ConfigModel(initialValues: [
            "window-padding-x": .string("12,4"),
            "window-padding-y": .string("8,2")
        ])
        let opts = PreviewBridge.translate(m)
        XCTAssertEqual(opts.paddingX, 12)
        XCTAssertEqual(opts.paddingY, 8)
    }

    func test_themeColorsArgPassedThrough() {
        let m = ConfigModel(initialValues: ["theme": .string("Anything")])
        let custom = XtermTheme.tokyoNightStorm
        XCTAssertEqual(PreviewBridge.translate(m, themeColors: custom).theme.background, "#24283b")
    }

    func test_noThemeColors_fallsBackToMocha() {
        let m = ConfigModel(initialValues: ["theme": .string("Anything")])
        // ThemeLoader hasn't loaded anything yet — preview shouldn't be blank, should show Mocha.
        XCTAssertEqual(PreviewBridge.translate(m).theme.background, "#1e1e2e")
    }

    func test_parseThemeName_dropsLightDarkPrefix() {
        XCTAssertEqual(PreviewBridge.parseThemeName("light:Latte,dark:Mocha"), "Mocha")
        XCTAssertEqual(PreviewBridge.parseThemeName("dark:Mocha,light:Latte"), "Mocha")
        XCTAssertEqual(PreviewBridge.parseThemeName("Plain Name"), "Plain Name")
        XCTAssertEqual(PreviewBridge.parseThemeName(""), "")
    }

    func test_jsonSerializable() throws {
        let opts = PreviewBridge.translate(ConfigModel(initialValues: [:]))
        let data = try JSONEncoder().encode(opts)
        XCTAssertFalse(data.isEmpty)
    }
}
