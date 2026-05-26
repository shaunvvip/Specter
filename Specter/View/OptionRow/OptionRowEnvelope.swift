import SwiftUI

struct OptionRowEnvelope<Content: View>: View {
    let entry: OptionEntry
    @Binding var isExpanded: Bool
    @ViewBuilder var control: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.key).font(.system(.body, design: .monospaced))
                Spacer()
                control()
                    .frame(maxWidth: 200, alignment: .trailing)
            }
            if isExpanded {
                Text(entry.docMarkdown)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture { isExpanded.toggle() }
    }
}
