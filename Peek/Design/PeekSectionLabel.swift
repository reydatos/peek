import SwiftUI

/// The small uppercase label above a group.
struct PeekSectionLabel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption)
            .bold()
            .textCase(.uppercase)
            .tracking(1)
            .foregroundStyle(PeekTheme.mist)
    }
}
