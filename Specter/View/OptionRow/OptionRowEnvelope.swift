import SwiftUI

/// One option row, rendered as a light card with key (monospaced), help text, and value chip.
///
/// Layout (within 342px inspector pane, minus 28px*2 outer + 16px*2 inner = 254px usable):
/// - left text column: flex (key truncates, help wraps up to 3 lines)
/// - right control slot: compact, fixed widths capped so text column always wins
struct OptionRowEnvelope<Content: View>: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env
    @ViewBuilder var control: () -> Content

    private var isDirty: Bool {
        env.configModel.dirtyKeys.contains(entry.key)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.key)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Palette.inspectorText)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(entry.docMarkdown)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: 0x697386))
                    .lineSpacing(2)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            control()
                .layoutPriority(0)
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
            .lineLimit(1)
            .padding(.horizontal, 10)
            .frame(minWidth: 56, minHeight: 28)
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
