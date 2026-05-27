import SwiftUI

/// Bottom-of-workspace rail showing the comma-separated list of dirty keys
/// plus an "Apply safely" button that opens the confirmation sheet.
/// Hidden when nothing is dirty.
struct UnsavedRail: View {
    @Environment(AppEnvironment.self) private var env
    @Binding var showApplySheet: Bool

    var body: some View {
        let dirty = env.configModel.dirtyKeys
        if dirty.isEmpty {
            EmptyView()
        } else {
            HStack(spacing: 14) {
                Text("Unsaved changes")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(Color(hex: 0x94a3b8))
                Text(dirty.sorted().joined(separator: ", "))
                    .font(FontSpec.monoSmall)
                    .foregroundStyle(Color(hex: 0xe2e8f0))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 12)
                Button {
                    showApplySheet = true
                } label: {
                    Text("Apply safely")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 30)
                        .background(
                            LinearGradient(colors: [Color(hex: 0x4fa5ff), Color(hex: 0x2563eb)],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: Color(hex: 0x2563eb).opacity(0.32), radius: 8, y: 3)
                }
                .buttonStyle(.plain)
                .disabled(env.isApplying)
            }
            .padding(.leading, 18).padding(.trailing, 12)
            .frame(height: 46)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: 0x121722)))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.line, lineWidth: 1))
        }
    }
}
