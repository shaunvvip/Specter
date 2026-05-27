import SwiftUI

/// Wraps the WKWebView preview in a translucent gradient halo + a terminal-style
/// titlebar (traffic lights, file name, "LIVE PREVIEW" pill).
///
/// The titlebar and halo colors derive from the currently-loaded theme so
/// switching themes updates the full preview frame, not just the xterm.js body.
struct PreviewHalo: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        VStack(spacing: 0) {
            terminalTitleBar
            PreviewPane()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(termBgColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(termAccent.opacity(0.22), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [haloTop, haloBottom],
                        startPoint: .top, endPoint: .bottom
                    )
                )
        )
        .shadow(color: termAccent.opacity(0.14), radius: 24)
    }

    // MARK: - Title bar

    private var terminalTitleBar: some View {
        HStack(spacing: 8) {
            Circle().fill(Color(hex: 0xff5f57)).frame(width: 10, height: 10)
            Circle().fill(Color(hex: 0xfebc2e)).frame(width: 10, height: 10)
            Circle().fill(Color(hex: 0x28c840)).frame(width: 10, height: 10)
            Text(terminalTitleText)
                .font(.system(size: 12))
                .foregroundStyle(titleTextColor)
                .padding(.leading, 14)
            Spacer()
            Text("LIVE PREVIEW")
                .font(.system(size: 10, weight: .heavy))
                .tracking(0.6)
                .foregroundStyle(termAccent)
                .padding(.horizontal, 11).padding(.vertical, 3)
                .background(Capsule().fill(termBgColor.darkened(0.10)))
                .overlay(Capsule().stroke(termAccent.opacity(0.32), lineWidth: 1))
        }
        .padding(.horizontal, 16)
        .frame(height: 42)
        .background(titleBarBg)
        .overlay(
            Rectangle().frame(height: 1).foregroundStyle(Color.white.opacity(0.07)),
            alignment: .bottom
        )
    }

    // MARK: - Derived colors

    /// Background color of the actual terminal area (the chrome behind xterm.js).
    private var termBgColor: Color {
        Color(hexString: env.currentThemeColors.background, fallback: Color(hex: 0x15151f))
    }

    /// Title bar — slightly brighter than the terminal bg for visual separation.
    private var titleBarBg: Color {
        termBgColor.lightened(0.06)
    }

    /// File / shell label on the title bar — uses the theme's foreground at low contrast.
    private var titleTextColor: Color {
        Color(hexString: env.currentThemeColors.foreground, fallback: Color(hex: 0xaab6c8))
            .opacity(0.7)
    }

    /// Accent (LIVE PREVIEW pill border + outer halo stroke).
    /// Uses cyan from the theme palette which most schemes have.
    private var termAccent: Color {
        Color(hexString: env.currentThemeColors.cyan, fallback: Color(hex: 0x7dd3fc))
    }

    private var haloTop: Color { termBgColor.lightened(0.18).opacity(0.65) }
    private var haloBottom: Color { termBgColor.darkened(0.05).opacity(0.65) }

    private var terminalTitleText: String {
        let theme: String = {
            if case .string(let s) = env.configModel.values["theme"], !s.isEmpty { return s }
            return "default"
        }()
        return "ghostty · zsh · \(theme)"
    }
}
