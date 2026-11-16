import SwiftUI

/// The pose reference for the people in the photo. The complete picture shows, with no cut, as large as the
/// outer display permits (owner decision, 2026-11-15). It is at the far right, because the hinge cover of an
/// open iPhone Duo is at the left. The rest of the display is black, as the frame of the phone.
///
/// The display is used to its edges: the view does not stop at the safe area, and the placement keeps the
/// picture clear of the occluded areas that the system reports.
///
/// The frame of the pack accent shows that this is not the live camera. The picture has no "Pose reference" label
/// and no pose name on it (owner decisions, 2026-11-15). The motion label of an animated pose is on the picture.
struct OuterReferenceStage: View {
    let cue: PoseCue
    let accent: Color

    var body: some View {
        GeometryReader { proxy in
            // The pose pictures are 3:4. This is the largest 3:4 frame that is clear of the occluded areas.
            let picture = StripPlacement.outerColumn(in: proxy.size, avoiding: proxy.occlusions)
            PoseArt(cue: cue, cornerRadius: 0, showsMove: true)
                .overlay {
                    Rectangle()
                        .strokeBorder(accent, lineWidth: 5)
                        .accessibilityHidden(true)
                }
                .overlay(alignment: .topLeading) {
                    PoseMotionChip(cue: cue, background: PeekTheme.surface)
                        .padding()
                }
                .frame(width: picture.width, height: picture.height)
                .position(x: picture.midX, y: picture.midY)
        }
        .background(PeekTheme.cameraChrome)
        .ignoresSafeArea()
    }
}
