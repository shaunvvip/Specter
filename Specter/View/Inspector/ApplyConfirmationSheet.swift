import SwiftUI

/// Sub-page shown before writing to disk. Dark theme matches global app palette.
/// Layout matches the `.apply-card` block in design/specter-high-fidelity.html:
/// header + auto-backup chip + 3 numbered steps + diff + Cancel/Apply.
struct ApplyConfirmationSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            ApplyHeader()
            ApplySteps()
            ApplyDiff()
            ApplyActions(isPresented: $isPresented)
        }
        .frame(width: 560)
        .background(Palette.panel)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Palette.lineStrong, lineWidth: 1))
    }
}

// MARK: - Header

private struct ApplyHeader: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Ready to apply \(env.configModel.dirtyKeys.count) changes?")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(Palette.text)
                Text("Click Apply now to write to ~/.config/ghostty/config")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.muted)
            }
            Spacer()
            Text("Auto-backup enabled")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(Palette.green)
                .padding(.horizontal, 11).padding(.vertical, 7)
                .background(Capsule().fill(Palette.green.opacity(0.12)))
                .overlay(Capsule().stroke(Palette.green.opacity(0.35), lineWidth: 1))
        }
        .padding(.horizontal, 26)
        .frame(height: 76)
        .background(Palette.panel2)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(Palette.line), alignment: .bottom)
    }
}

// MARK: - Steps

private struct ApplySteps: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            step(num: 1, title: "Create timestamped backup",
                 desc: "Saved under ~/Library/Application Support/Specter/Backups.")
            step(num: 2, title: "Patch only dirty keys",
                 desc: "Preserve comments, blank lines, unknown options byte-for-byte.")
            step(num: 3, title: "Request Ghostty reload",
                 desc: "AppleScript best-effort; falls back to a toast if denied.")
        }
        .padding(26)
    }

    private func step(num: Int, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(num)")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(Palette.cyan)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Palette.cyan.opacity(0.14)))
                .overlay(Circle().stroke(Palette.cyan.opacity(0.32), lineWidth: 1))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.text)
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.muted)
                    .lineSpacing(2)
            }
        }
    }
}

// MARK: - Diff

private struct ApplyDiff: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(diffLines, id: \.self) { line in
                Text(line)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(diffColor(for: line))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: 0x0d1019)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.line, lineWidth: 1))
        .padding(.horizontal, 26).padding(.bottom, 20)
    }

    private var diffLines: [String] {
        let dirty = env.configModel.dirtyKeys.sorted()
        var lines: [String] = []
        for key in dirty {
            let new = env.configModel.values[key]
            let old = env.configModel.appliedValue(for: key)
            if let oldVal = old {
                lines.append("- \(key) = \(oldVal.stringRepresentation)")
            }
            if let newVal = new {
                lines.append("+ \(key) = \(newVal.stringRepresentation)")
            } else if old != nil {
                lines.append("# (removed) \(key)")
            }
        }
        if lines.isEmpty { lines.append("(no changes)") }
        return lines
    }

    private func diffColor(for line: String) -> Color {
        if line.hasPrefix("- ") { return Palette.red }
        if line.hasPrefix("+ ") { return Palette.green }
        return Palette.muted
    }
}

// MARK: - Actions

private struct ApplyActions: View {
    @Environment(AppEnvironment.self) private var env
    @Binding var isPresented: Bool

    var body: some View {
        HStack {
            Spacer()
            HoverButton {
                isPresented = false
            } label: { hovering in
                Text("Cancel")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Palette.soft)
                    .padding(.horizontal, 18).frame(height: 36)
                    .background(RoundedRectangle(cornerRadius: 9)
                        .fill(hovering ? Palette.panel3.opacity(0.85) : Palette.panel3))
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(Palette.line, lineWidth: 1))
            }
            .keyboardShortcut(.cancelAction)

            HoverButton {
                Task {
                    await env.apply()
                    if env.applyError == nil { isPresented = false }
                }
            } label: { hovering in
                HStack(spacing: 6) {
                    if env.isApplying {
                        ProgressView().controlSize(.small).tint(.white)
                        Text("Applying…")
                    } else {
                        Text("Apply now")
                    }
                }
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 18).frame(height: 36)
                .background(
                    LinearGradient(
                        colors: hovering
                            ? [Color(hex: 0x66b3ff), Color(hex: 0x3a7af0)]
                            : [Color(hex: 0x4fa5ff), Color(hex: 0x2868e6)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .shadow(color: Palette.blue.opacity(0.32), radius: 8, y: 3)
            }
            .disabled(env.isApplying)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 26).padding(.bottom, 24)
    }
}
