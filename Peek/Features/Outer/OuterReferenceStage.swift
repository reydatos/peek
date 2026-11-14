import SwiftUI

/// The pose reference for the people in the photo: a label, the picture in a frame of the pack accent, and the cue.
/// The frame and the label show that this is not the live camera.
struct OuterReferenceStage: View {
    let cue: PoseCue
    let accent: Color

    var body: some View {
        VStack {
            HStack {
                PeekChip(text: .poseReference, background: PeekTheme.fill)
                PoseMotionChip(cue: cue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            PoseReferenceFrame(cue: cue, accent: accent, lineWidth: 5, cornerRadius: PeekTheme.photoCorner, showsMove: true)
                .frame(maxHeight: .infinity)
            Text(cue.name)
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
                .foregroundStyle(PeekTheme.ink)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PeekTheme.page)
    }
}
