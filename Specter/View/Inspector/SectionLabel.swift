import SwiftUI

/// Small uppercase label that groups option rows within a category (e.g. "VISUAL", "TYPOGRAPHY").
struct SectionLabel: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .black))
            .tracking(1)
            .foregroundStyle(Palette.inspectorLabel)
            .padding(.top, 22).padding(.bottom, 10)
    }
}
