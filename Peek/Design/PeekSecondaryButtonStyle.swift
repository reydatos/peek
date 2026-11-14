import SwiftUI

/// A secondary action: a soft fill with dark text.
struct PeekSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PeekFont.sans(.headline))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(PeekTheme.ink)
            .background(PeekTheme.mist, in: .rect(cornerRadius: PeekTheme.corner))
            .contentShape(.rect(cornerRadius: PeekTheme.corner))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
