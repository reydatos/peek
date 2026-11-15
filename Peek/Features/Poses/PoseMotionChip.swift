import SwiftUI
import UIKit

/// The label of a pose that has a move: "Animated", or "Still" with Reduce Motion on.
/// A pose with no start picture has no label.
struct PoseMotionChip: View {
    let cue: PoseCue
    /// The fill. On a picture it is `surface`. On the page it is `fill`.
    var background = PeekTheme.fill
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if UIImage(named: cue.startAssetName) != nil {
            PeekChip(text: reduceMotion ? .still : .animated, background: background)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }
}
