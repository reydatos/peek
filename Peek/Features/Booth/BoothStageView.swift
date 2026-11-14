import PeekCore
import SwiftUI

/// The inner display's picture, inset with rounded corners, and the cue line below it.
///
/// The picture is the live frame, the shot in review, or the finished strip. The inner display shows the full
/// frame (aspect-fit). The outer display has its own views in `Features/Outer`.
struct BoothStageView: View {
    let model: BoothSessionModel
    /// True when no outer display shows the cue. The people in the photo then read this display.
    let isSubjectFacing: Bool
    /// False in the wide booth: the leading panel shows the pose reference there.
    var showsPoseArt = true
    /// True on a tall display: the photo runs edge to edge, and the camera bar has the cue line.
    var isFullBleed = false

    var body: some View {
        if isFullBleed {
            photo
        } else {
            VStack(alignment: .leading) {
                photo
                CueLine(model: model, isSubjectFacing: isSubjectFacing)
            }
            .padding()
        }
    }

    private var photo: some View {
        ZStack {
            PeekTheme.fill
            if model.isComplete, !showsPoseArt {
                // The wide booth shows the two layouts side by side.
                FinishedPairView(model: model)
                    .padding()
            } else if model.isComplete, let strip = model.strip {
                // The finished strip stays inside the safe area, so the camera housing hides no shot.
                FinishedStripView(strip: strip)
                    .padding()
            } else if model.isComplete {
                // The strip is not drawn yet.
                ProgressView()
            } else if let still = model.stillImage {
                Image(uiImage: still)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel(Text(.capturedPhoto))
            } else {
                // The front camera shows a mirror picture, as a selfie does. The saved shot is not a mirror picture.
                CameraPreviewView(session: model.capture.session, deviceID: model.deviceID, isMirrored: model.isSelfie)
                    .accessibilityLabel(Text(.livePreview))
            }
        }
        .clipShape(.rect(cornerRadius: isFullBleed ? 0 : PeekTheme.photoCorner))
        .overlay(alignment: .topLeading) {
            VStack(alignment: .leading) {
                StageChips(model: model)
                BoothBanners(model: model)
            }
            .padding()
            // On a tall display, the close button and the More menu are above the labels.
            .padding(.top, isFullBleed ? PeekTheme.touchTarget : 0)
        }
        .overlay(alignment: .bottomLeading) {
            // With one screen, the pose reference moves into the camera view.
            if showsPoseArt, isSubjectFacing, canStepPose, let cue = model.currentCue {
                PoseGuide(cue: cue, accent: model.accent, isLarge: true)
                    .padding()
            }
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
