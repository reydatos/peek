import PeekCore
import SwiftUI

/// The choice of the paper color of the finished picture: cream, white, or black.
struct FramePicker: View {
    @Bindable var model: BoothSessionModel

    var body: some View {
        PeekSegmentedChoice(selection: $model.frame, options: [
            (FrameColor.cream, .frameCream),
            (FrameColor.white, .frameWhite),
            (FrameColor.black, .frameBlack),
        ])
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(.frameLabel))
    }
}
