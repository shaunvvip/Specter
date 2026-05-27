import SwiftUI

struct StatusCard: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(headline)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.inspectorText)
                Text(subhead)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.inspectorMuted)
            }
            Spacer()
            Circle().fill(dotColor).frame(width: 14, height: 14)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .frame(height: 64)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(Palette.inspectorSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14).stroke(Palette.inspectorBorder, lineWidth: 1)
        )
    }

    private var headline: String {
        let n = env.configModel.dirtyKeys.count
        return n > 0 ? "\(n) unsaved edits" : "No unsaved changes"
    }
    private var subhead: String {
        env.configModel.dirtyKeys.isEmpty
            ? "Disk is in sync with the editor."
            : "No file writes until Apply."
    }
    private var dotColor: Color {
        env.configModel.dirtyKeys.isEmpty ? Color(hex: 0x10b981) : Palette.statusDot
    }
}
