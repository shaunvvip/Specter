import SwiftUI

/// Custom 56px in-window titlebar that matches design/specter-high-fidelity.html.
/// Native traffic lights stay where macOS puts them (top-left); we leave 70px of
/// leading space for them and then lay out path / app name / search / Reset / Apply.
struct TitleBar: View {
    @Environment(AppEnvironment.self) private var env
    @Binding var showCommandPalette: Bool
    @Binding var showApplySheet: Bool
    var onResetClearsSearch: () -> Void = {}

    var body: some View {
        HStack(spacing: 14) {
            Color.clear.frame(width: 70)

            pathChip
            appName
            Spacer()
            searchPill
            resetButton
            applyButton
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(
            Color(hex: 0x181c25)
                .overlay(Rectangle().frame(height: 1).foregroundStyle(Palette.line), alignment: .bottom)
        )
    }

    private var pathChip: some View {
        Text("~/.config/ghostty/config")
            .font(FontSpec.monoSmall)
            .foregroundStyle(Color(hex: 0x9aa6bc))
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: 0x10131a)))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Palette.line, lineWidth: 1))
    }

    private var appName: some View {
        Text("Specter")
            .font(.system(size: 16, weight: .heavy))
            .foregroundStyle(Palette.text)
    }

    private var searchPill: some View {
        HoverButton {
            showCommandPalette = true
        } label: { hovering in
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: 0x738197))
                Text("Search every option")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: 0x738197))
                Spacer(minLength: 8)
                Text("⌘K")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(Palette.muted)
            }
            .padding(.horizontal, 10)
            .frame(width: 245, height: 32)
            .background(RoundedRectangle(cornerRadius: 8).fill(hovering ? Color(hex: 0x161a23) : Color(hex: 0x10131a)))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Palette.line, lineWidth: 1))
        }
        .help("Open command palette (⌘K)")
    }

    private var resetButton: some View {
        HoverButton {
            env.resetAll()
            onResetClearsSearch()
        } label: { hovering in
            Text("Reset")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(Color(hex: 0xd7deea))
                .padding(.horizontal, 13)
                .frame(height: 32)
                .background(RoundedRectangle(cornerRadius: 8)
                    .fill(hovering ? Palette.panel3.opacity(0.8) : Palette.panel3))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Palette.line, lineWidth: 1))
        }
        .disabled(env.configModel.dirtyKeys.isEmpty)
        .opacity(env.configModel.dirtyKeys.isEmpty ? 0.5 : 1)
    }

    private var applyButton: some View {
        HoverButton {
            showApplySheet = true
        } label: { hovering in
            HStack(spacing: 6) {
                if env.isApplying {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                    Text("Applying…")
                } else {
                    Text("Apply")
                    if !env.configModel.dirtyKeys.isEmpty {
                        Text("\(env.configModel.dirtyKeys.count)")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                }
            }
            .font(.system(size: 12, weight: .heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(height: 32)
            .background(
                LinearGradient(
                    colors: hovering
                        ? [Color(hex: 0x66b3ff), Color(hex: 0x3a7af0)]
                        : [Color(hex: 0x4fa5ff), Color(hex: 0x2868e6)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: Color(hex: 0x3c82f6).opacity(0.32), radius: 10, y: 4)
        }
        .disabled(env.configModel.dirtyKeys.isEmpty || env.isApplying)
        .opacity(env.configModel.dirtyKeys.isEmpty ? 0.45 : 1)
    }
}
