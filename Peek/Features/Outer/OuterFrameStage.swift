import SwiftUI

/// The live frame or the captured shot in one fixed 4:3 crop, with the caption below it.
///
/// The crop does not move between live framing, countdown, and the captured shot. The caption is below the crop,
/// so the numeral stays below faces. Lookbook page 03.
struct OuterFrameStage: View {
    let model: BoothSessionModel

    var body: some View {
        VStack(spacing: 0) {
            Color.black
                .aspectRatio(4 / 3, contentMode: .fit)
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
                .clipped()
            OuterCaption(
                phase: model.state.phase,
                cueName: model.currentCue?.name ?? .samplePrompt,
                shotNumber: model.state.currentSlotID.index + 1
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(PeekTheme.ink)
    }
}
