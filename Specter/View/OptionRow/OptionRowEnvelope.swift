import SwiftUI

/// One option row, rendered as a light card with key (monospaced), help text, and value chip.
/// Highlights with a soft blue tint when dirty.
struct OptionRowEnvelope<Content: View>: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env
    @ViewBuilder var control: () -> Content

    private var isDirty: Bool {
        env.configModel.dirtyKeys.contains(entry.key)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.key)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Palette.inspectorText)
                Text(entry.docMarkdown)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: 0x697386))
                    .lineSpacing(1.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            control()
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .frame(minHeight: 78)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isDirty ? Palette.inspectorActiveBg : Palette.inspectorSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isDirty ? Palette.inspectorActiveBorder : Palette.inspectorBorder,
                        lineWidth: 1)
        )
        .shadow(color: isDirty ? Palette.inspectorActiveBorder.opacity(0.16) : .clear, radius: 6)
        .padding(.bottom, 12)
    }
}

// MARK: - Shared value chip

struct ValueChip: View {
    let text: String
    var isAction: Bool = false
    var isDirty: Bool = false

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .heavy))
            .foregroundStyle(textColor)
            .padding(.horizontal, 12)
            .frame(minWidth: 78, minHeight: 32)
            .background(
                RoundedRectangle(cornerRadius: 8).fill(bgColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isAction ? Palette.inspectorActionText.opacity(0.2) : .clear, lineWidth: 1)
            )
    }

    private var bgColor: Color {
        if isAction { return Palette.inspectorActionBg }
        if isDirty  { return Palette.inspectorActiveChipBg }
        return Palette.inspectorChipBg
    }
    private var textColor: Color {
        if isAction { return Palette.inspectorActionText }
        if isDirty  { return Palette.inspectorActiveText }
        return Palette.inspectorChipText
    }
}
