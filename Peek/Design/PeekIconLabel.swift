import SwiftUI

/// A round icon control with an accessibility label: close, more, previous, next.
struct PeekIconLabel: View {
    let text: LocalizedStringResource
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .labelStyle(.iconOnly)
            .font(.headline)
            .foregroundStyle(PeekTheme.ink)
            .frame(width: PeekTheme.touchTarget, height: PeekTheme.touchTarget)
            .background(PeekTheme.fill, in: .circle)
            .contentShape(.circle)
    }
}
