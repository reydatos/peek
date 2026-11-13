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
                if model.isComplete, let strip = model.strip {
                    FinishedStripView(strip: strip)
                } else if let still = model.stillImage {
                    Color.clear
                        .overlay {
                            Image(uiImage: still)
                                .resizable()
                                .aspectRatio(contentMode: usesFrameFeed ? .fill : .fit)
                        }
                        .clipped()
                        .accessibilityLabel(Text(.capturedPhoto))
                } else if let outerPose {
                    OuterPoseStage(cue: outerPose.cue, picture: outerPose.picture, model: model, isMirrored: isMirrored)
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
            // The finished strip stays inside the safe area, so the camera housing hides no shot.
            .ignoresSafeArea(edges: stageEdges)
            if outerPose != nil {
                // The pose picture is the cue. The outer display shows no pose name.
                EmptyView()
            } else if canStepPose, !isSubjectFacing {
                PoseStepper(model: model)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                CueOverlay(
                    phase: model.state.phase,
                    isSubjectFacing: isSubjectFacing,
                    prompt: model.currentCue?.name ?? .samplePrompt,
                    art: usesFrameFeed ? model.currentCue : nil
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // A sideways swipe on the inner display changes the pose.
        .gesture(
            DragGesture().onEnded { drag in
                guard canStepPose, abs(drag.translation.width) > abs(drag.translation.height) else { return }
                model.stepPose(by: drag.translation.width < 0 ? 1 : -1)
            },
            isEnabled: canStepPose
        )
    }

    /// The pose picture for the outer display while the booth waits for a shot. It clears at countdown. PRD FR-05.
    private var outerPose: (cue: PoseCue, picture: UIImage)? {
        guard usesFrameFeed, model.state.phase == .ready, !model.isComplete, model.stillImage == nil,
              let cue = model.currentCue, let picture = UIImage(named: cue.assetName)
        else { return nil }
        return (cue, picture)
    }

    /// The finished strip and the pose picture stay inside the safe area, clear of the camera housing.
    private var stageEdges: Edge.Set {
        if model.isComplete || outerPose != nil {
            return []
        }
        if usesFrameFeed {
            return .all
        }
        return isSubjectFacing ? [] : .horizontal
    }

    /// True on the inner display while the booth waits for a shot.
    private var canStepPose: Bool {
        !usesFrameFeed && model.state.phase == .ready
    }
}
