import SwiftUI

/// The one filled main action of a screen: red with a white label.
struct PeekPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(isEnabled ? PeekTheme.onRed : PeekTheme.inkSecondary)
            .background(isEnabled ? PeekTheme.red : PeekTheme.fill, in: .rect(cornerRadius: PeekTheme.primaryButtonCorner))
            .contentShape(.rect(cornerRadius: PeekTheme.primaryButtonCorner))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
