import SwiftUI

/// A secondary action: the soft fill with an ink label.
struct PeekSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(isEnabled ? PeekTheme.ink : PeekTheme.inkSecondary)
            .background(PeekTheme.fill, in: .rect(cornerRadius: PeekTheme.buttonCorner))
            .contentShape(.rect(cornerRadius: PeekTheme.buttonCorner))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
