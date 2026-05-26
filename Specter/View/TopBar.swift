import SwiftUI

struct TopBar: View {
    @Environment(AppEnvironment.self) private var env
    @Binding var searchQuery: String

    var body: some View {
        HStack(spacing: 12) {
            Button(action: applyTapped) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Apply")
                    if !env.configModel.dirtyKeys.isEmpty {
                        Text("\(env.configModel.dirtyKeys.count)")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.orange.opacity(0.85), in: Capsule())
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(env.configModel.dirtyKeys.isEmpty || env.isApplying)

            Button(action: resetTapped) {
                Label("Reset", systemImage: "arrow.uturn.backward")
            }
            .buttonStyle(.bordered)
            .disabled(env.configModel.dirtyKeys.isEmpty)

            Spacer()

            HStack {
                Image(systemName: "magnifyingglass")
                TextField("⌘K  搜索 200+ 设置", text: $searchQuery)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: 320)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.bar)
    }

    private func applyTapped() {
        Task { await env.apply() }
    }

    private func resetTapped() {
        env.resetAll()
    }
}
