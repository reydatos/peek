import SwiftUI

/// A button of the side rail: the icon above the label. The primary form is red.
struct PeekRailButtonStyle: ButtonStyle {
    var isPrimary = false
    @Environment(\.isEnabled) private var isEnabled
    @ScaledMetric(relativeTo: .footnote) private var minHeight = 54

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(PeekRailLabelStyle())
            .font(.footnote)
            .fontWeight(.semibold)
            .multilineTextAlignment(.center)
            .padding(PeekTheme.tightSpace)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .foregroundStyle(isEnabled ? (isPrimary ? PeekTheme.onRed : PeekTheme.ink) : PeekTheme.inkSecondary)
            .background(isPrimary && isEnabled ? PeekTheme.red : PeekTheme.fill, in: .rect(cornerRadius: PeekTheme.buttonCorner))
            .contentShape(.rect(cornerRadius: PeekTheme.buttonCorner))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// The icon above the title.
struct PeekRailLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: PeekTheme.tightSpace) {
            configuration.icon
            configuration.title
        }
    }
}
