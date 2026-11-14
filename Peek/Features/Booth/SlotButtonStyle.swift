import SwiftUI

/// The slot rail's button look: the cell with no change, so a slot with no shot keeps its full contrast.
struct SlotButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
