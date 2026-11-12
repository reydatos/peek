import SwiftUI

/// What the people in front of the lens see on the outer display.
struct OuterCueView: View {
    let model: BoothSessionModel

    var body: some View {
        BoothStageView(model: model, isMirrored: model.isOuterPreviewMirrored, isSubjectFacing: true)
    }
}
