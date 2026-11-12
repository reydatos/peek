import SwiftUI

/// The main action: a cream pill with dark text.
struct PeekPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .foregroundStyle(PeekTheme.ink)
            .background(PeekTheme.cream, in: .capsule)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
