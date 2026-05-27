import Foundation

enum SettingCategory: String, CaseIterable, Identifiable, Hashable {
    case appearance
    case font
    case window
    case cursor
    case mouse
    case clipboard
    case shellIntegration
    case keybind
    case macos
    case advanced
    case unknown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .appearance: return "外观"
        case .font: return "字体"
        case .window: return "窗口"
        case .cursor: return "光标"
        case .mouse: return "鼠标"
        case .clipboard: return "剪贴板"
        case .shellIntegration: return "Shell Integration"
        case .keybind: return "键位"
        case .macos: return "macOS"
        case .advanced: return "高级"
        case .unknown: return "未识别"
        }
    }

    var sfSymbol: String {
        switch self {
        case .appearance: return "paintpalette"
        case .font: return "textformat"
        case .window: return "macwindow"
        case .cursor: return "cursorarrow"
        case .mouse: return "computermouse"
        case .clipboard: return "doc.on.clipboard"
        case .shellIntegration: return "terminal"
        case .keybind: return "keyboard"
        case .macos: return "apple.logo"
        case .advanced: return "gearshape.2"
        case .unknown: return "questionmark.square"
        }
    }

    /// Letter glyph (per design/specter-high-fidelity.html). Sidebar shows a
    /// rounded color tile with one bold letter rather than a SF Symbol.
    var glyph: String {
        switch self {
        case .appearance: return "A"
        case .font: return "F"
        case .window: return "W"
        case .cursor: return "C"
        case .mouse: return "M"
        case .clipboard: return "B"
        case .shellIntegration: return "S"
        case .keybind: return "K"
        case .macos: return "⌘"
        case .advanced: return "•"
        case .unknown: return "?"
        }
    }

    /// One-line description shown under the title in the sidebar nav row.
    var sidebarSubtitle: String {
        switch self {
        case .appearance: return "Theme, opacity, blur"
        case .font: return "Family, size, ligature"
        case .window: return "Padding, titlebar"
        case .cursor: return "Shape and motion"
        case .mouse: return "Selection, scroll"
        case .clipboard: return "Paste protection"
        case .shellIntegration: return "Integration mode"
        case .keybind: return "Read-only in v1"
        case .macos: return "Native chrome, alt key"
        case .advanced: return "Power-user options"
        case .unknown: return "Preserved verbatim"
        }
    }
}
