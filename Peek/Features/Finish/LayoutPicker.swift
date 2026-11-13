import PeekCore
import SwiftUI

/// The choice between the vertical strip and the 2x2 layout. PRD FR-01.
struct LayoutPicker: View {
    @Bindable var model: BoothSessionModel

    var body: some View {
        Picker(selection: $model.layout) {
            Text(.layoutStrip).tag(PeekCore.Layout.verticalStrip)
            Text(.layoutGrid).tag(PeekCore.Layout.grid2x2)
        } label: {
            Text(.layoutLabel)
        }
        .pickerStyle(.segmented)
    }
}
