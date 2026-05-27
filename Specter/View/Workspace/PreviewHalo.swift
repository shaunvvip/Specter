import SwiftUI

/// Wraps the WKWebView preview in a translucent gradient halo + a terminal-style
/// titlebar (traffic lights, file name, "LIVE PREVIEW" pill).
struct PreviewHalo: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        VStack(spacing: 0) {
            terminalTitleBar
            PreviewPane()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(hex: 0x15151f))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(hex: 0x7dd3fc).opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x203756).opacity(0.68), Color(hex: 0x131925).opacity(0.66)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
        )
        .shadow(color: Palette.blueHi.opacity(0.12), radius: 24)
    }

    private var terminalTitleBar: some View {
        HStack(spacing: 8) {
            Circle().fill(Color(hex: 0xff5f57)).frame(width: 10, height: 10)
            Circle().fill(Color(hex: 0xfebc2e)).frame(width: 10, height: 10)
            Circle().fill(Color(hex: 0x28c840)).frame(width: 10, height: 10)
            Text(terminalTitleText)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: 0xaab6c8))
                .padding(.leading, 14)
            Spacer()
            Text("LIVE PREVIEW")
                .font(.system(size: 10, weight: .heavy))
                .tracking(0.6)
                .foregroundStyle(Palette.cyan)
                .padding(.horizontal, 11).padding(.vertical, 3)
                .background(
                    Capsule().fill(Color(hex: 0x0f172a))
                )
                .overlay(
                    Capsule().stroke(Palette.cyan.opacity(0.32), lineWidth: 1)
                )
        }
        .padding(.horizontal, 16)
        .frame(height: 42)
        .background(Color(hex: 0x1d2030))
        .overlay(
            Rectangle().frame(height: 1).foregroundStyle(Color.white.opacity(0.07)),
            alignment: .bottom
        )
    }

    private var terminalTitleText: String {
        let theme: String = {
            if case .string(let s) = env.configModel.values["theme"], !s.isEmpty { return s }
            return "default"
        }()
        return "ghostty · zsh · \(theme)"
    }
}
