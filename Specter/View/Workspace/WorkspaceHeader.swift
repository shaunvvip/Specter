import SwiftUI

struct WorkspaceHeader: View {
    let eyebrow: String
    let title: String
    let subcopy: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(eyebrow)
                .font(FontSpec.eyebrow)
                .tracking(1.4)
                .foregroundStyle(Palette.blueHi)
                .padding(.bottom, 10)
            Text(title)
                .font(FontSpec.h2)
                .foregroundStyle(Palette.text)
            Text(subcopy)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: 0x8490a3))
                .padding(.top, 11)
        }
    }
}
