import SwiftUI

/// Plain-style button that exposes a hover flag to its label builder, so each
/// call site can swap colors/backgrounds on hover without writing a custom
/// ButtonStyle every time.
///
/// ```swift
/// HoverButton {
///     someAction()
/// } label: { hovering in
///     Text("Apply")
///         .background(hovering ? Color.blue.opacity(0.8) : .blue)
/// }
/// ```
struct HoverButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: (Bool) -> Label
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            label(hovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
