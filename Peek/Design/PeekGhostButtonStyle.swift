import SwiftUI

/// A secondary action: an outlined pill.
struct PeekGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PeekFont.sans(.headline))
            .padding()
            .foregroundStyle(PeekTheme.cream)
            .background(Capsule().strokeBorder(PeekTheme.line))
            .contentShape(.capsule)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
