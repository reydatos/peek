import PeekCore
import SwiftUI

/// The live frame or the captured shot for the people in the photo. The picture covers the whole outer display,
/// and its right edge is at the right edge of the display. The hinge cover of an open iPhone Duo is at the left,
/// so the part of the picture that it hides is the left part.
///
/// The picture does not move or change size between live framing, countdown, and the captured shot.
/// The pose guide and the caption are in the column at the right, which stays in view. The caption is on a card at
/// the bottom, so the numeral stays below faces.
struct OuterFrameStage: View {
    let model: BoothSessionModel

    var body: some View {
        GeometryReader { proxy in
            // The shots are 4:3.
            let picture = StripPlacement.rightPinnedFill(in: proxy.size, aspect: 4 / 3)
            let column = StripPlacement.outerColumn(in: proxy.size, avoiding: proxy.occlusions)
            Color.black
                .overlay {
                    // The live view stays in place below the shot, so it does not start again after review.
                    FramePreviewView(capture: model.capture, deviceID: model.deviceID, isMirrored: model.isOuterPreviewMirrored)
                        .accessibilityLabel(Text(.livePreview))
                    // The ghost: the clip of the pose over the live picture, so the people line up with it.
                    // The clip is the upright center column of the camera picture, so it has that place here.
                    if model.shownClipLook == .ghost, model.stillImage == nil, let url = model.currentCue?.clipURL {
                        PoseGhost(url: url, opacity: model.ghostOpacity)
                            .aspectRatio(PoseGhost.clipAspect, contentMode: .fit)
                    }
                    if let still = model.stillImage {
                        Image(uiImage: still)
                            .resizable()
                            .scaledToFill()
                            .accessibilityLabel(Text(.capturedPhoto))
                    }
                }
                .clipped()
                .frame(width: picture.width, height: picture.height)
                .position(x: picture.midX, y: picture.midY)
            VStack(alignment: .leading) {
                // The pose guide shows during live framing only. The picture has no "Live" label
                // (owner decision, 2026-11-15).
                if model.state.phase == .ready, let cue = model.currentCue {
                    PoseGuide(cue: cue, accent: model.accent)
                }
                Spacer()
                if hasCaption {
                    OuterCaption(
                        phase: model.state.phase,
                        shotNumber: model.state.currentSlotID.index + 1,
                        countdownLength: model.countdown.seconds
                    )
                    .frame(maxWidth: .infinity)
                    .background(PeekTheme.surface, in: .rect(cornerRadius: PeekTheme.cardCorner))
                }
            }
            .padding()
            .frame(width: column.width, height: column.height)
            .position(x: column.midX, y: column.midY)
        }
        .clipped()
        .background(PeekTheme.page)
        // The picture covers the display to its edges, not only the safe area.
        .ignoresSafeArea()
    }

    private var hasCaption: Bool {
        switch model.state.phase {
        // Live framing has no caption: the pose name does not cover the picture (owner decision, 2026-11-15).
        case .setup, .ready, .complete: false
        default: true
        }
    }
}
