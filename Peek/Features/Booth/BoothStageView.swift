import PeekCore
import SwiftUI

/// The inner display's picture, inset with rounded corners, and the cue line below it.
///
/// The picture is the live frame, the shot in review, or the finished strip. A tall display is a viewfinder:
/// the upright frame at the full width, with the camera bar below it. A wide display shows the part that the
/// finished picture keeps: the photo card has the shape of one shot in the strip, and the picture covers it.
/// The outer display has its own views in `Features/Outer`.
struct BoothStageView: View {
    let model: BoothSessionModel
    /// True when no outer display shows the cue. The people in the photo then read this display.
    let isSubjectFacing: Bool
    /// False in the wide booth: the side rail shows the pose reference there.
    var showsPoseArt = true
    /// True on a tall display: the photo is a viewfinder at the full width, and it has the pose card.
    var isFullBleed = false
    var body: some View {
        if isFullBleed {
            photo
                .aspectRatio(Self.uprightAspect, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else {
            VStack(alignment: .leading) {
                photo
                    .modifier(PhotoCardShape(aspect: cardAspect))
                CueLine(model: model, isSubjectFacing: isSubjectFacing)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
        }
    }

    /// The card has the shape of one shot in the finished picture, so it shows the part that the strip keeps.
    /// A finished set has no single picture, so its card fills the space.
    private var cardAspect: CGFloat? {
        model.isComplete ? nil : StripRenderer.cellAspect
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
                // The shot covers the card, as it covers its cell in the strip. An overlay keeps the card's size.
                Color.clear
                    .overlay {
                        Image(uiImage: still)
                            .resizable()
                            .scaledToFill()
                    }
                    .accessibilityElement()
                    .accessibilityLabel(Text(.capturedPhoto))
            } else {
                // The front camera shows a mirror picture, as a selfie does. The saved shot is not a mirror picture.
                CameraPreviewView(
                    session: model.capture.session,
                    deviceID: model.deviceID,
                    isMirrored: model.isSelfie
                )
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
        .overlay(alignment: .bottomTrailing) {
            if !isFullBleed {
                ZoomChips(model: model)
                    .padding()
            }
        }
        .overlay(alignment: .bottomLeading) {
            if isFullBleed {
                // The viewfinder has no cue line, so the pose and its name are one card in the corner.
                // The card and the zoom choices share one row, so a long pose name goes to a second line
                // and covers no zoom choice.
                HStack(alignment: .bottom) {
                    if showsPoseCard, let cue = model.currentCue {
                        ViewfinderPoseCard(cue: cue, accent: model.accent, isLarge: isSubjectFacing)
                    }
                    Spacer(minLength: 0)
                    ZoomChips(model: model)
                }
                .padding()
            } else if isSubjectFacing, canStepPose, let cue = model.currentCue {
                // With one screen, the pose reference moves into the camera view.
                if showsPoseArt {
                    PoseGuide(cue: cue, accent: model.accent, isLarge: true)
                        .padding()
                } else {
                    // The wide booth: the people in the photo read this display from a distance, so the
                    // reference is large and shows the move. The side rail then has no pose reference.
                    // Its height is a part of the photo, so it stays below the labels at each text size.
                    GeometryReader { proxy in
                        PoseReferenceFrame(cue: cue, accent: model.accent, showsMove: true)
                            .frame(height: proxy.size.height * Self.wideGuideFraction)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    }
                    .padding()
                    .allowsHitTesting(false)
                }
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

    /// The height of the one-screen pose reference in the wide booth, as a part of the photo height.
    /// This is a design value.
    private static let wideGuideFraction = 0.6

    /// The shape of the upright picture of a 4:3 camera: the width divided by the height. This is a design value.
    private static let uprightAspect: CGFloat = 3.0 / 4.0

    /// True while the booth waits for a shot.
    private var canStepPose: Bool {
        model.state.phase == .ready
    }

    /// True while the pose card shows: not in the countdown or the capture, so it covers no face then.
    private var showsPoseCard: Bool {
        switch model.state.phase {
        case .ready, .paused, .review: true
        case .setup, .countdown, .capturePending, .complete: false
        }
    }
}

/// Gives the photo card the aspect of its picture, or lets it fill the space when there is no aspect.
private struct PhotoCardShape: ViewModifier {
    let aspect: CGFloat?

    func body(content: Content) -> some View {
        if let aspect {
            content.aspectRatio(aspect, contentMode: .fit)
        } else {
            content
        }
    }
}
