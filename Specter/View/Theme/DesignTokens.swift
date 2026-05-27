import SwiftUI

// MARK: - Palette
// Tokens sourced from design/specter-high-fidelity.html.
// The app's chrome is dark; the Inspector pane is the only light surface.

enum Palette {
    // --- Dark surfaces (workspace, sidebar, toolbar) ---
    static let bg          = Color(hex: 0x090b10)
    static let panel       = Color(hex: 0x11141b)
    static let panel2      = Color(hex: 0x171b24)
    static let panel3      = Color(hex: 0x202632)
    static let sidebarBg   = Color(hex: 0x101218)
    static let titlebarBg  = Color(hex: 0x181c25)

    // --- Text on dark ---
    static let text  = Color(hex: 0xf7fafc)
    static let muted = Color(hex: 0x93a1b7)
    static let soft  = Color(hex: 0xc6d0df)
    static let dim   = Color(hex: 0x697386)

    // --- Lines / dividers ---
    static let line       = Color.white.opacity(0.08)
    static let lineStrong = Color.white.opacity(0.14)

    // --- Accents ---
    static let blue   = Color(hex: 0x4ea8ff)
    static let blueHi = Color(hex: 0x73e4ff)
    static let cyan   = Color(hex: 0x7dd3fc)
    static let green  = Color(hex: 0x82e6aa)
    static let yellow = Color(hex: 0xf9c76b)
    static let red    = Color(hex: 0xff7676)
    static let purple = Color(hex: 0xb99cff)

    // --- Inspector light surface ---
    static let inspectorBg     = Color(hex: 0xf6f7f9)
    static let inspectorSurface = Color.white
    static let inspectorBorder = Color(hex: 0xe4e7ec)
    static let inspectorText   = Color(hex: 0x111827)
    static let inspectorMuted  = Color(hex: 0x667085)
    static let inspectorLabel  = Color(hex: 0x8a94a6)

    // Inspector "active" highlight (selected/dirty row)
    static let inspectorActiveBg     = Color(hex: 0xeef6ff)
    static let inspectorActiveBorder = Color(hex: 0x93c5fd)
    static let inspectorActiveText   = Color(hex: 0x1d4ed8)
    static let inspectorActiveChipBg = Color(hex: 0xdbeafe)

    // Inspector value chip default
    static let inspectorChipBg   = Color(hex: 0xf3f4f6)
    static let inspectorChipText = Color(hex: 0x374151)
    static let inspectorActionBg = Color(hex: 0xe0f2fe)
    static let inspectorActionText = Color(hex: 0x0369a1)

    // Status dot
    static let statusDot = Color(hex: 0xf59e0b)
}

// MARK: - Spacing & radius

enum Metric {
    static let cardRadius: CGFloat = 14
    static let bigRadius: CGFloat = 22
    static let pillRadius: CGFloat = 999
    static let chipRadius: CGFloat = 10

    static let sidebarWidth: CGFloat = 216
    static let inspectorWidth: CGFloat = 342
    static let titleBarHeight: CGFloat = 56
}

// MARK: - Typography

enum FontSpec {
    static let mono = Font.system(.body, design: .monospaced)
    static let monoSmall = Font.system(size: 12, design: .monospaced)
    static let monoMedium = Font.system(size: 13, design: .monospaced)

    static let eyebrow = Font.system(size: 11, weight: .heavy)
    static let h1 = Font.system(size: 32, weight: .heavy)
    static let h2 = Font.system(size: 24, weight: .heavy)
    static let h3 = Font.system(size: 18, weight: .bold)
    static let body = Font.system(size: 14)
    static let caption = Font.system(size: 12)
    static let micro = Font.system(size: 11)
    static let label = Font.system(size: 10, weight: .black)
}

// MARK: - Color hex helper

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xff) / 255.0
        let g = Double((hex >> 8) & 0xff) / 255.0
        let b = Double(hex & 0xff) / 255.0
        self = Color(red: r, green: g, blue: b)
    }
}
