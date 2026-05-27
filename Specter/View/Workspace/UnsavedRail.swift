import SwiftUI

/// Bottom-of-workspace rail showing the comma-separated list of dirty keys
/// plus an "Apply safely" button. Hidden when nothing is dirty.
struct UnsavedRail: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        let dirty = env.configModel.dirtyKeys
        if dirty.isEmpty {
            EmptyView()
        } else {
            HStack(spacing: 14) {
                Text("Unsaved changes")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x94a3b8))
                Text(dirty.sorted().joined(separator: ", "))
                    .font(FontSpec.monoSmall)
                    .foregroundStyle(Color(hex: 0xe2e8f0))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 12)
                Button {
                    Task { await env.apply() }
                } label: {
                    Text("Apply safely")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 8).fill(Color(hex: 0x2563eb))
                        )
                }
                .buttonStyle(.plain)
                .disabled(env.isApplying)
            }
            .padding(.leading, 18).padding(.trailing, 12)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 14).fill(Color(hex: 0x121722))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14).stroke(Palette.line, lineWidth: 1)
            )
        }
    }
}
