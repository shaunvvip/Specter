import SwiftUI

/// Sub-page shown before writing to disk. Matches the `.apply-card` block in
/// design/specter-high-fidelity.html — backup badge + 3 numbered steps + diff
/// preview + Cancel / Apply now buttons.
struct ApplyConfirmationSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            steps
            diff
            actions
        }
        .frame(width: 560)
        .background(Color(hex: 0xf7f8fa))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .colorScheme(.light)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Ready to apply \(env.configModel.dirtyKeys.count) changes?")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(Color(hex: 0x101828))
                Text("Click Apply now to write to ~/.config/ghostty/config")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: 0x667085))
            }
            Spacer()
            Text("Backup ready")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(Color(hex: 0x067647))
                .padding(.horizontal, 13).padding(.vertical, 8)
                .background(
                    Capsule().fill(Color(hex: 0xecfdf3))
                )
                .overlay(
                    Capsule().stroke(Color(hex: 0xabefc6), lineWidth: 1)
                )
        }
        .padding(.horizontal, 30)
        .frame(height: 76)
        .background(Color.white)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(Color(hex: 0xe4e7ec)), alignment: .bottom)
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 18) {
            step(num: 1, title: "Create timestamped backup",
                 desc: "Stored under ~/Library/Application Support/Specter/Backups.")
            step(num: 2, title: "Patch only dirty keys",
                 desc: "Preserve comments, blank lines, unknown options byte-for-byte.")
            step(num: 3, title: "Request Ghostty reload",
                 desc: "AppleScript best-effort; falls back to a toast if denied.")
        }
        .padding(30)
    }

    private func step(num: Int, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(num)")
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(Color(hex: 0x1d4ed8))
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color(hex: 0xdbeafe)))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x101828))
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: 0x667085))
            }
        }
    }

    private var diff: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(diffLines, id: \.self) { line in
                Text(line)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(diffColor(for: line))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(Color(hex: 0x111827))
        )
        .padding(.horizontal, 30).padding(.bottom, 22)
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
        if line.hasPrefix("- ") { return Color(hex: 0xef4444) }
        if line.hasPrefix("+ ") { return Color(hex: 0x22c55e) }
        return Color(hex: 0xa1a1aa)
    }

    private var actions: some View {
        HStack {
            Spacer()
            Button {
                isPresented = false
            } label: {
                Text("Cancel")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Color(hex: 0x344054))
                    .padding(.horizontal, 18).frame(height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 9).fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 9).stroke(Color(hex: 0xd0d5dd), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)

            Button {
                Task {
                    await env.apply()
                    isPresented = false
                }
            } label: {
                Text(env.isApplying ? "Applying…" : "Apply now")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18).frame(height: 38)
                    .background(
                        LinearGradient(colors: [Color(hex: 0x4fa5ff), Color(hex: 0x2563eb)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                    .shadow(color: Color(hex: 0x2563eb).opacity(0.32), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(env.isApplying)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 30).padding(.bottom, 30)
    }
}
