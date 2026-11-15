import SwiftUI

/// The live frame or the captured shot in one fixed 4:3 crop, with the caption below it.
///
/// The crop does not move between live framing, countdown, and the captured shot. The caption is below the crop,
/// so the numeral stays below faces.
struct OuterFrameStage: View {
    let model: BoothSessionModel

    var body: some View {
        GeometryReader { proxy in
            // The stage uses the largest area that nothing covers, such as the area beside the hinge cover.
            let area = StripPlacement.freeArea(in: proxy.size, avoiding: proxy.occlusions)
            stage
                .frame(width: area.width, height: area.height)
                .position(x: area.midX, y: area.midY)
        }
        .background(PeekTheme.page)
    }

    private var stage: some View {
        VStack(alignment: .trailing, spacing: 0) {
            // The crop has the full width of the area, with no margin. When the area is too low for that,
            // the crop is at the right.
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
                // The crop gets its space first. The caption gets the remainder.
                .layoutPriority(1)
                .overlay(alignment: .topLeading) {
                    // The label and the pose guide show during live framing only. They are clear of the outer camera.
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
            OuterCaption(
                phase: model.state.phase,
                cueName: model.currentCue?.name ?? .samplePrompt,
                shotNumber: model.state.currentSlotID.index + 1,
                countdownLength: model.countdown.seconds
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
