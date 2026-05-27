import SwiftUI

/// The 4-up "featured themes" swatch row above the live preview.
///
/// Each swatch shows the theme's actual background as the tile color. Names are
/// matched against `env.availableThemes` so we never try to apply a theme that
/// isn't installed.
struct ThemeStrip: View {
    @Environment(AppEnvironment.self) private var env
    let onOpenAllThemes: () -> Void

    /// Featured candidate names + their representative accent colors. We pick
    /// the first 4 that actually exist in availableThemes.
    private static let candidates: [(name: String, accent: UInt32)] = [
        ("TokyoNight Storm",   0x7aa2f7),
        ("Catppuccin Mocha",   0xcba6f7),
        ("Gruvbox Dark",       0xfabd2f),
        ("Nord",               0x88c0d0),
        ("Dracula",            0xff79c6),
        ("Solarized Dark",     0xb58900),
        ("One Half Dark",      0x61afef),
        ("Ayu Dark",           0xffb454),
    ]

    private struct Featured: Identifiable {
        var id: String { name }
        let name: String
        let accent: Color
    }

    /// Pick the first 4 themes from `candidates` that match an installed theme
    /// (case-insensitive lookup against availableThemes).
    private var featured: [Featured] {
        let installed = Set(env.availableThemes.map { $0.lowercased() })
        var picked: [Featured] = []
        for (name, accent) in Self.candidates {
            if installed.contains(name.lowercased()) {
                picked.append(Featured(name: name, accent: Color(hex: accent)))
                if picked.count == 4 { break }
            }
        }
        return picked
    }

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
                    Button(action: onOpenAllThemes) {
                        Text("All themes  \u{2192}")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(Color(hex: 0xbdeeff))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Capsule().fill(Palette.blue.opacity(0.10)))
                            .overlay(Capsule().stroke(Palette.blueHi.opacity(0.24), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }

            if featured.isEmpty {
                emptyState
            } else {
                HStack(spacing: 14) {
                    ForEach(featured) { theme in
                        swatch(theme)
                    }
                }
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 15)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: 0x141820)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.line, lineWidth: 1))
    }

    private var emptyState: some View {
        Text(env.ghostyBinaryFound
             ? "Loading themes…"
             : "Install Ghostty to load theme list")
            .font(.system(size: 12))
            .foregroundStyle(Color(hex: 0x8490a3))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }

    private func swatch(_ theme: Featured) -> some View {
        let current = env.configModel.string(for: "theme")
        let isSelected = current == theme.name

        return Button {
            env.configModel.set("theme", .string(theme.name))
            Task { await env.reloadCurrentThemeColors() }
        } label: {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 99)
                    .fill(theme.accent)
                    .frame(width: 34, height: 6)
                Text(theme.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xe5edf7))
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0x1a1c24)))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Palette.blueHi : Color.white.opacity(0.10),
                            lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
