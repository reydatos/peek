import SwiftUI

/// The inner display's picture: the live frame, the shot in review, or the finished strip, with the cue for the state.
///
/// The inner display shows the full frame (aspect-fit). The outer display has its own views in `Features/Outer`.
struct BoothStageView: View {
    let model: BoothSessionModel
    /// True when no outer display shows the cue. The people in the photo then read this display, so the cue is large.
    let isSubjectFacing: Bool
    /// False in the wide booth: the side rail shows the pose reference there.
    var showsPoseArt = true

    var body: some View {
        ZStack {
            PeekTheme.ink
            if model.isComplete, let strip = model.strip {
                // The finished strip stays inside the safe area, so the camera housing hides no shot.
                FinishedStripView(strip: strip)
            } else if let still = model.stillImage {
                Image(uiImage: still)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel(Text(.capturedPhoto))
            } else {
                CameraPreviewView(session: model.capture.session, deviceID: model.deviceID, isMirrored: false)
                    .accessibilityLabel(Text(.livePreview))
            }
            if canStepPose, !isSubjectFacing {
                PoseStepper(model: model)
            } else {
                CueOverlay(
                    phase: model.state.phase,
                    isSubjectFacing: isSubjectFacing,
                    prompt: model.currentCue?.name ?? .samplePrompt,
                    art: showsPoseArt ? model.currentCue : nil
                )
            }
            // The pose name is at the top with two displays, and the cue card is at the bottom with one.
            StageChips(model: model)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isSubjectFacing ? .topLeading : .bottomLeading)
                .padding()
        }
        // A sideways swipe changes the pose.
        .gesture(
            DragGesture().onEnded { drag in
                guard canStepPose, abs(drag.translation.width) > abs(drag.translation.height) else { return }
                model.stepPose(by: drag.translation.width < 0 ? 1 : -1)
            },
            isEnabled: canStepPose
        )
    }

    /// True while the booth waits for a shot.
    private var canStepPose: Bool {
        model.state.phase == .ready
    }
}
