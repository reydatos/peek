import PeekCore
import SwiftUI
import UIKit

/// What the people in front of the lens see on the outer display. They see one thing at a time:
/// the pose reference, the live frame, the countdown, the captured shot, or the finished strip.
///
/// The live frame, the countdown, and the captured shot use one fixed crop with a caption below it.
struct OuterCueView: View {
    let model: BoothSessionModel

    var body: some View {
        stage
    }

    @ViewBuilder private var stage: some View {
        if model.isComplete, let strip = model.strip {
            // The finished strip stays inside the safe area, so the camera housing hides no shot.
            FinishedStripView(strip: strip, isRightAligned: true)
                .background(PeekTheme.page)
        } else if model.state.phase == .ready, model.state.subjectView == .reference,
                  let cue = model.currentCue, cue.picture != nil
        {
            OuterReferenceStage(cue: cue, accent: model.accent)
        } else {
            OuterFrameStage(model: model)
        }
    }
}
