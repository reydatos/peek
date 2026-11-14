import PeekCore
import SwiftUI

/// What the people in front of the lens see on the outer display.
///
/// While the booth waits for a shot, the pose picture fills the display and the live frame is small.
/// At countdown the picture clears (PRD FR-05). The live frame, the countdown, and the captured shot then
/// use one fixed crop with a caption below it (lookbook page 03).
struct OuterCueView: View {
    let model: BoothSessionModel

    var body: some View {
        if model.isComplete, let strip = model.strip {
            // The finished strip stays inside the safe area, so the camera housing hides no shot.
            FinishedStripView(strip: strip)
                .background(PeekTheme.ink)
        } else if model.state.phase == .ready, let cue = model.currentCue, let picture = UIImage(named: cue.assetName) {
            OuterPoseStage(cue: cue, picture: picture, model: model, isMirrored: model.isOuterPreviewMirrored)
        } else {
            OuterFrameStage(model: model)
        }
    }
}
