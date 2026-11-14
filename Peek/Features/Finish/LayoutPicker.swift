import PeekCore
import SwiftUI

/// The choice between the vertical strip and the 2x2 layout. PRD FR-01.
struct LayoutPicker: View {
    @Bindable var model: BoothSessionModel

    var body: some View {
        PeekSegmentedChoice(selection: $model.layout, options: [
            (PeekCore.Layout.verticalStrip, .layoutStrip),
            (PeekCore.Layout.grid2x2, .layoutGrid),
        ])
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(.layoutLabel))
    }
}
