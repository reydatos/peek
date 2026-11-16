import SwiftUI

/// The pose reference for the people in the photo. The picture covers the whole outer display, and its right edge
/// is at the right edge of the display. The hinge cover of an open iPhone Duo is at the left, so the part of the
/// picture that it hides is the left part.
///
/// The label and the frame of the pack accent show that this is not the live camera. The label is in the column
/// at the right, which stays in view. The picture has no pose name on it (owner decision, 2026-11-15), so the
/// people see the full picture.
struct OuterReferenceStage: View {
    let cue: PoseCue
    let accent: Color

    var body: some View {
        GeometryReader { proxy in
            // The pose pictures are 3:4.
            let picture = StripPlacement.rightPinnedFill(in: proxy.size, aspect: 3 / 4)
            let column = StripPlacement.outerColumn(in: proxy.size, avoiding: proxy.occlusions)
            PoseArt(cue: cue, cornerRadius: 0, showsMove: true)
                .frame(width: picture.width, height: picture.height)
                .position(x: picture.midX, y: picture.midY)
            Rectangle()
                .strokeBorder(accent, lineWidth: 5)
                .accessibilityHidden(true)
            VStack {
                HStack {
                    PeekChip(text: .poseReference)
                    PoseMotionChip(cue: cue, background: PeekTheme.surface)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
            .padding()
            .frame(width: column.width, height: column.height)
            .position(x: column.midX, y: column.midY)
        }
        .clipped()
        .background(PeekTheme.page)
    }
}
