import SwiftUI

/// The one filled main action of a task: warm ivory with dark text. Lookbook: "One filled primary action per task".
struct PeekPrimaryButtonStyle: ButtonStyle {
    /// The red fill is for the booth entry only.
    var isBoothEntry = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PeekFont.sans(.headline))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(isBoothEntry ? Color.white : PeekTheme.ink)
            .background(isBoothEntry ? PeekTheme.accent : PeekTheme.cream, in: .rect(cornerRadius: PeekTheme.corner))
            .contentShape(.rect(cornerRadius: PeekTheme.corner))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
