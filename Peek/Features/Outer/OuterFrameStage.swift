import PeekCore
import SwiftUI

/// The live frame or the captured shot for the people in the photo. It fills the column at the far right of the
/// outer display, the same column as the pose reference. The hinge cover of an open iPhone Duo is at the left.
///
/// The picture does not move or change size between live framing, countdown, and the captured shot.
/// The caption is on a card at the bottom of the picture, so the numeral stays below faces.
/// The picture fills a 3:4 column, so it shows less at the sides than the 4:3 shot has.
struct OuterFrameStage: View {
    let model: BoothSessionModel

    var body: some View {
        GeometryReader { proxy in
            let column = StripPlacement.outerColumn(in: proxy.size, avoiding: proxy.occlusions)
            Color.black
                .overlay {
                    // The live view stays in place below the shot, so it does not start again after review.
                    FramePreviewView(capture: model.capture, deviceID: model.deviceID, isMirrored: model.isOuterPreviewMirrored)
                        .accessibilityLabel(Text(.livePreview))
                    if let still = model.stillImage {
                        Image(uiImage: still)
                            .resizable()
                            .scaledToFill()
                            .accessibilityLabel(Text(.capturedPhoto))
                    }
                }
                .clipShape(.rect(cornerRadius: PeekTheme.photoCorner))
                .overlay(alignment: .topLeading) {
                    // The label and the pose guide show during live framing only.
                    if model.state.phase == .ready {
                        VStack(alignment: .leading) {
                            PeekChip(text: .live)
                            if let cue = model.currentCue {
                                PoseGuide(cue: cue, accent: model.accent)
                            }
                        }
                        .padding()
                    }
                }
                .overlay(alignment: .bottom) {
                    if hasCaption {
                        OuterCaption(
                            phase: model.state.phase,
                            cueName: model.currentCue?.name ?? .samplePrompt,
                            shotNumber: model.state.currentSlotID.index + 1,
                            countdownLength: model.countdown.seconds
                        )
                        .frame(maxWidth: .infinity)
                        .background(PeekTheme.surface, in: .rect(cornerRadius: PeekTheme.cardCorner))
                        .padding()
                    }
                }
                .frame(width: column.width, height: column.height)
                .position(x: column.midX, y: column.midY)
        }
        .background(PeekTheme.page)
    }

    private var hasCaption: Bool {
        switch model.state.phase {
        case .setup, .complete: false
        default: true
        }
    }
}
