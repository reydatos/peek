import SwiftUI

/// The pose reference for the people in the photo: the full picture, as large as the display permits,
/// at the far right. The hinge cover of an open iPhone Duo is at the left, so the picture stays in view.
///
/// The label and the frame of the pack accent show that this is not the live camera. The label and the cue
/// are on the picture, so the picture gets all of the height.
struct OuterReferenceStage: View {
    let cue: PoseCue
    let accent: Color

    var body: some View {
        GeometryReader { proxy in
            // The pose pictures are 3:4.
            let frame = StripPlacement.frame(in: proxy.size, avoiding: proxy.occlusions, aspect: 3 / 4, isRightAligned: true)
            PoseReferenceFrame(cue: cue, accent: accent, lineWidth: 5, cornerRadius: PeekTheme.photoCorner, showsMove: true)
                .overlay(alignment: .topLeading) {
                    HStack {
                        PeekChip(text: .poseReference)
                        PoseMotionChip(cue: cue, background: PeekTheme.surface)
                    }
                    .padding()
                }
                .overlay(alignment: .bottom) {
                    Text(cue.name)
                        .font(.largeTitle)
                        .bold()
                        .multilineTextAlignment(.center)
                        .foregroundStyle(PeekTheme.ink)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(PeekTheme.surface, in: .rect(cornerRadius: PeekTheme.cardCorner))
                        .padding()
                }
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
        }
        .background(PeekTheme.page)
    }
}
