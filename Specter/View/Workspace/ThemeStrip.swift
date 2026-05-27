import SwiftUI

/// The 4-up "featured themes" swatch row above the live preview.
///
/// Each swatch shows the theme's background as the tile color, plus a small
/// accent bar in a representative palette color. Clicking applies the theme.
struct ThemeStrip: View {
    @Environment(AppEnvironment.self) private var env

    private struct FeaturedTheme {
        let name: String       // Theme name as Ghostty knows it
        let displayName: String
        let background: UInt32
        let accent: UInt32
    }

    private let featured: [FeaturedTheme] = [
        FeaturedTheme(name: "TokyoNight Storm", displayName: "Tokyo Night", background: 0x1a1b26, accent: 0x7aa2f7),
        FeaturedTheme(name: "Catppuccin Mocha", displayName: "Catppuccin", background: 0x1e1e2e, accent: 0xcba6f7),
        FeaturedTheme(name: "Gruvbox Dark", displayName: "Gruvbox", background: 0x1d2021, accent: 0xfabd2f),
        FeaturedTheme(name: "Nord", displayName: "Nord", background: 0x2e3440, accent: 0x88c0d0),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text("Theme gallery")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xdce4ef))
                Spacer()
                HStack(spacing: 10) {
                    Text("\(featured.count) featured picks")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: 0x8490a3))
                    Text("All themes  \u{2192}")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(Color(hex: 0xbdeeff))
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(
                            Capsule().fill(Palette.blue.opacity(0.10))
                        )
                        .overlay(
                            Capsule().stroke(Palette.blueHi.opacity(0.24), lineWidth: 1)
                        )
                }
            }

            HStack(spacing: 14) {
                ForEach(featured, id: \.name) { theme in
                    swatch(theme)
                }
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 16).fill(Color(hex: 0x141820))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(Palette.line, lineWidth: 1)
        )
    }

    private func swatch(_ theme: FeaturedTheme) -> some View {
        let current: String = {
            if case .string(let s) = env.configModel.values["theme"] { return s }
            return ""
        }()
        let isSelected = current == theme.name

        return Button {
            env.configModel.set("theme", .string(theme.name))
            Task { await env.reloadCurrentThemeColors() }
        } label: {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 99)
                    .fill(Color(hex: theme.accent))
                    .frame(width: 34, height: 6)
                Text(theme.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xe5edf7))
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(
                RoundedRectangle(cornerRadius: 10).fill(Color(hex: theme.background))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Palette.blueHi : Color.white.opacity(0.10),
                            lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
