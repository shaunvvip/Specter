import Foundation

struct XtermOptions: Codable, Equatable {
    var fontFamily: String
    var fontSize: Int
    var backgroundOpacity: Double
    var paddingX: Int
    var paddingY: Int
    var cursorStyle: String
    var cursorBlink: Bool
    var theme: XtermTheme
}

struct XtermTheme: Codable, Equatable {
    var background: String
    var foreground: String
    var cursor: String
    var black: String
    var red: String
    var green: String
    var yellow: String
    var blue: String
    var magenta: String
    var cyan: String
    var white: String
    var brightBlack: String
    var brightRed: String
    var brightGreen: String
    var brightYellow: String
    var brightBlue: String
    var brightMagenta: String
    var brightCyan: String
    var brightWhite: String

    static let mocha = XtermTheme(
        background: "#1e1e2e", foreground: "#cdd6f4", cursor: "#f5e0dc",
        black: "#45475a", red: "#f38ba8", green: "#a6e3a1", yellow: "#f9e2af",
        blue: "#89b4fa", magenta: "#f5c2e7", cyan: "#94e2d5", white: "#bac2de",
        brightBlack: "#585b70", brightRed: "#f38ba8", brightGreen: "#a6e3a1",
        brightYellow: "#f9e2af", brightBlue: "#89b4fa", brightMagenta: "#f5c2e7",
        brightCyan: "#94e2d5", brightWhite: "#a6adc8"
    )

    static let tokyoNightStorm = XtermTheme(
        background: "#24283b", foreground: "#a9b1d6", cursor: "#c0caf5",
        black: "#32344a", red: "#f7768e", green: "#9ece6a", yellow: "#e0af68",
        blue: "#7aa2f7", magenta: "#ad8ee6", cyan: "#449dab", white: "#9699a8",
        brightBlack: "#444b6a", brightRed: "#ff7a93", brightGreen: "#b9f27c",
        brightYellow: "#ff9e64", brightBlue: "#7da6ff", brightMagenta: "#bb9af7",
        brightCyan: "#0db9d7", brightWhite: "#acb0d0"
    )

    static func builtin(named name: String) -> XtermTheme? {
        switch name.lowercased() {
        case "catppuccin mocha", "mocha": return .mocha
        case "tokyonight storm", "tokyonight night", "tokyonight": return .tokyoNightStorm
        default: return nil
        }
    }
}
