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
    /// True on a tall display: the photo is a viewfinder at the full width, with the pose picture in its corner.
    var isFullBleed = false
    var body: some View {
        if isFullBleed {
            photo
                .aspectRatio(Self.uprightAspect, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else {
            VStack(alignment: .leading, spacing: Self.cueSpace) {
                photo
                    .modifier(PhotoCardShape(aspect: cardAspect))
                    .overlay(alignment: .bottom) {
                        // The countdown is at the center below the photo (owner decision, 2026-11-17), in the space
                        // that the cue line keeps for it. It is not in the layout, so the photo has the same size.
                        // A line with no height at the bottom edge of the photo. The countdown hangs below it.
                        Color.clear
                            .frame(height: 0)
                            .overlay(alignment: .top) {
                                if case let .countdown(remaining) = model.state.phase {
                                    CountdownView(remaining: remaining, total: model.countdown.seconds, isLarge: isSubjectFacing)
                                        .fixedSize()
                                        .padding(.top, Self.cueSpace)
                                }
                            }
                    }
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
            if model.isComplete, let strip = model.strip {
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
                    holder: model.preview,
                    deviceID: model.deviceID,
                    isMirrored: model.isSelfie,
                    generation: model.preview.generation
                )
                .accessibilityLabel(Text(.livePreview))
            }
        }
        .overlay {
            // The ghost is above the live picture and inside its shape. The camera view below it does not change.
            if model.shownClipLook == .ghost, let url = model.currentCue?.clipURL {
                PoseGhost(url: url, opacity: model.ghostOpacity)
            }
        }
        .clipShape(.rect(cornerRadius: isFullBleed ? 0 : PeekTheme.photoCorner))
        .overlay {
            // The viewfinder has no cue line, so the countdown is on the picture, large, on a card.
            if isFullBleed, case let .countdown(remaining) = model.state.phase {
                CountdownView(remaining: remaining, total: model.countdown.seconds, isLarge: true)
                    .padding()
                    .background(PeekTheme.surface, in: .rect(cornerRadius: PeekTheme.cardCorner))
            }
        }
        .overlay(alignment: .topLeading) {
            VStack(alignment: .leading) {
                // The wide booth shows the shot number one time, on the cue line below the photo
                // (owner decision, 2026-11-15). The viewfinder of a tall display has no cue line.
                if isFullBleed {
                    StageChips(model: model)
                }
                BoothBanners(model: model)
                // The duet chip is at the top, clear of the zoom choices at the bottom of the viewfinder.
                DuetChip(model: model)
                if let start = model.attemptStart {
                    RecordingSign(start: start)
                }
                #if DEBUG
                    if model.shownClipLook == .ghost {
                        GhostOpacityStepper(model: model)
                    }
                #endif
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
                // The viewfinder has no cue line and no pose name (owner decision, 2026-11-15): the pose picture
                // alone is in the corner.
                // The zoom choices are in the center, as the other controls of the viewfinder. An invisible copy
                // of the pose picture at the right keeps them there. With too little width, they go to the right.
                // The arrows make the pose picture wide, so this row has no fixed space: it then fits a 393-point
                // display.
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .bottom, spacing: 0) {
                        poseCorner
                        Spacer(minLength: 0)
                        ZoomChips(model: model)
                        Spacer(minLength: 0)
                        poseCorner.hidden()
                    }
                    HStack(alignment: .bottom) {
                        poseCorner
                        Spacer(minLength: 0)
                        ZoomChips(model: model)
                    }
                }
                .padding()
            } else if isSubjectFacing, canStepPose, let cue = model.currentCue {
                // With one screen, the pose reference moves into the camera view.
                PoseStepper(model: model) {
                    PoseClipButton(model: model) {
                        PoseGuide(cue: cue, accent: model.accent, isLarge: true)
                    }
                }
                .padding()
            }
        }
        .overlay {
            // The large clip is above the labels, the pose picture and the zoom choices. A tap beside it closes it.
            if model.shownClipLook == .large, let cue = model.currentCue, let url = cue.clipURL {
                ZStack {
                    PeekTheme.scrim
                        .onTapGesture { model.setClipLook(.corner) }
                        .accessibilityHidden(true)
                    PoseClipCard(model: model, cue: cue, url: url)
                        .padding()
                }
                .clipShape(.rect(cornerRadius: isFullBleed ? 0 : PeekTheme.photoCorner))
            }
        }
        // A sideways swipe changes the pose. A short slide of a thumb does not.
        .gesture(
            DragGesture(minimumDistance: Self.poseSwipeDistance).onEnded { drag in
                let width = drag.translation.width
                guard canStepPose, abs(width) >= Self.poseSwipeDistance, abs(width) > abs(drag.translation.height) else { return }
                model.stepPose(by: width < 0 ? 1 : -1)
            },
            isEnabled: canStepPose
        )
    }

    /// The sideways slide, in points, that changes the pose. The owner chose this value (2026-11-20).
    private static let poseSwipeDistance: CGFloat = 60

    /// The space between the photo and the line below it.
    private static let cueSpace = PeekTheme.tightSpace

    /// The shape of the upright picture of a 4:3 camera: the width divided by the height. This is a design value.
    private static let uprightAspect: CGFloat = 3.0 / 4.0

    /// True while the booth waits for a shot.
    private var canStepPose: Bool {
        model.state.phase == .ready
    }

    /// The pose picture in the corner of the viewfinder, with the arrows that change the pose.
    @ViewBuilder private var poseCorner: some View {
        if showsPoseCard, let cue = model.currentCue {
            PoseStepper(model: model) {
                PoseClipButton(model: model) {
                    PoseGuide(cue: cue, accent: model.accent, isLarge: isSubjectFacing)
                }
            }
        }
    }

    /// True while the pose picture shows: not in the countdown or the capture, so it covers no face then.
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
