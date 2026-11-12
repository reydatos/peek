import SwiftUI

/// The live frame or the captured still, with the cue for the current state.
///
/// Both displays use this view with one camera source. The preview uses aspect-fit, so each
/// display shows the full frame. Template crop guides come with milestone M3.
struct BoothStageView: View {
    let model: BoothSessionModel
    let isMirrored: Bool
    /// True when the people in the photo read this display. The cue is then large.
    let isSubjectFacing: Bool
    /// True on the outer display, where a preview layer shows no picture.
    var usesFrameFeed = false

    var body: some View {
        ZStack {
            Color.black
            if let still = model.stillImage {
                Image(uiImage: still)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel(Text(.capturedPhoto))
            } else if usesFrameFeed {
                FramePreviewView(capture: model.capture, deviceID: model.deviceID, isMirrored: isMirrored)
                    .accessibilityLabel(Text(.livePreview))
            } else {
                CameraPreviewView(session: model.capture.session, deviceID: model.deviceID, isMirrored: isMirrored)
                    .accessibilityLabel(Text(.livePreview))
            }
            CueOverlay(phase: model.state.phase, isSubjectFacing: isSubjectFacing)
        }
        .ignoresSafeArea(edges: isSubjectFacing ? [] : .horizontal)
    }
}
