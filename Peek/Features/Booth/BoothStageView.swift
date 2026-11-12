import SwiftUI

/// The live frame or the captured still, with the cue for the current state.
///
/// Both displays use this view with one camera source. The inner display uses aspect-fit and shows the full frame.
/// The outer display fills its screen, so it crops the frame. Template crop guides come with milestone M3.
struct BoothStageView: View {
    let model: BoothSessionModel
    let isMirrored: Bool
    /// True when the people in the photo read this display. The cue is then large.
    let isSubjectFacing: Bool
    /// True on the outer display, where a preview layer shows no picture.
    var usesFrameFeed = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            ZStack {
                Color.black
                if let still = model.stillImage {
                    Color.clear
                        .overlay {
                            Image(uiImage: still)
                                .resizable()
                                .aspectRatio(contentMode: usesFrameFeed ? .fill : .fit)
                        }
                        .clipped()
                        .accessibilityLabel(Text(.capturedPhoto))
                } else if usesFrameFeed {
                    FramePreviewView(capture: model.capture, deviceID: model.deviceID, isMirrored: isMirrored)
                        .accessibilityLabel(Text(.livePreview))
                } else {
                    CameraPreviewView(session: model.capture.session, deviceID: model.deviceID, isMirrored: isMirrored)
                        .accessibilityLabel(Text(.livePreview))
                }
            }
            // The outer display shows the picture edge to edge. The cue stays inside the safe area,
            // clear of the camera housing.
            .ignoresSafeArea(edges: usesFrameFeed ? .all : (isSubjectFacing ? [] : .horizontal))
            CueOverlay(
                phase: model.state.phase,
                isSubjectFacing: isSubjectFacing,
                prompt: model.currentCue?.name ?? .samplePrompt
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // PRD FR-05: the people in the photo see the reference. It clears at countdown.
            if usesFrameFeed, model.state.phase == .ready, let cue = model.currentCue {
                PoseArt(cue: cue)
                    .containerRelativeFrame(.horizontal, count: 3, spacing: 0)
                    .padding()
            }
        }
    }
}
