import SwiftUI

extension View {
    func compatGlassPanel(cornerRadius: CGFloat = 10) -> some View {
        glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
    }

    func compatGlassButton() -> some View {
        buttonStyle(.glass)
    }
}
