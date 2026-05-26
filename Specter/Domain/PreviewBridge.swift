import Foundation

enum PreviewBridge {
    static func translate(_ model: ConfigModel) -> XtermOptions {
        func str(_ key: String, default def: String) -> String {
            if case .string(let s) = model.values[key] { return s }
            return def
        }
        func int(_ key: String, default def: Int) -> Int {
            if case .integer(let i) = model.values[key] { return i }
            return def
        }
        func dbl(_ key: String, default def: Double) -> Double {
            if case .double(let d) = model.values[key] { return d }
            return def
        }
        func bool(_ key: String, default def: Bool) -> Bool {
            if case .bool(let b) = model.values[key] { return b }
            return def
        }

        let (px, py) = parsePadding(
            str("window-padding-x", default: "4,2"),
            str("window-padding-y", default: "6,0")
        )

        let themeName = parseThemeName(str("theme", default: ""))
        let theme = XtermTheme.builtin(named: themeName) ?? .mocha

        return XtermOptions(
            fontFamily: str("font-family", default: "JetBrains Mono"),
            fontSize: int("font-size", default: 14),
            backgroundOpacity: dbl("background-opacity", default: 1.0),
            paddingX: px,
            paddingY: py,
            cursorStyle: str("cursor-style", default: "block"),
            cursorBlink: bool("cursor-style-blink", default: true),
            theme: theme
        )
    }

    private static func parsePadding(_ x: String, _ y: String) -> (Int, Int) {
        let xVal = Int(x.split(separator: ",").first ?? "4") ?? 4
        let yVal = Int(y.split(separator: ",").first ?? "6") ?? 6
        return (xVal, yVal)
    }

    /// Accepts both `Mocha` and `light:Latte,dark:Mocha`; returns the dark name (current macOS Appearance can refine later).
    private static func parseThemeName(_ raw: String) -> String {
        if raw.contains(":") {
            for part in raw.split(separator: ",") {
                let kv = part.split(separator: ":", maxSplits: 1).map(String.init)
                if kv.count == 2, kv[0].trimmingCharacters(in: .whitespaces) == "dark" {
                    return kv[1].trimmingCharacters(in: .whitespaces)
                }
            }
        }
        return raw.trimmingCharacters(in: .whitespaces)
    }
}
