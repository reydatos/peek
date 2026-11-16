import SwiftUI

/// The pose reference for the people in the photo. The complete picture shows, with no cut, as large as the
/// outer display permits. It is at the far right, because the hinge cover of an open iPhone Duo is at the left.
///
/// The picture is 3:4 and the display has a different shape, so the complete picture can not cover the display.
/// A soft copy of the same picture, large enough to cover the display, is behind it. So the display has no
/// empty band, and the people see one picture that covers the screen (owner decision, 2026-11-15).
///
/// The display is used to its edges: the view does not stop at the safe area, and the placement keeps the
/// complete picture clear of the occluded areas that the system reports.
///
/// The frame of the pack accent is around the display. It shows that this is not the live camera. The picture has
/// no "Pose reference" label and no pose name on it. The motion label of an animated pose is on the picture.
struct OuterReferenceStage: View {
    let cue: PoseCue
    let accent: Color

    /// The blur of the copy behind the picture. This is a design value.
    private static let backdropBlur: CGFloat = 40

    var body: some View {
        GeometryReader { proxy in
            // The pose pictures are 3:4. This is the largest 3:4 frame that is clear of the occluded areas.
            let picture = StripPlacement.outerColumn(in: proxy.size, avoiding: proxy.occlusions)
            if let image = UIImage(named: cue.assetName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .blur(radius: Self.backdropBlur, opaque: true)
                    .clipped()
                    .accessibilityHidden(true)
            }
            PoseArt(cue: cue, cornerRadius: 0, showsMove: true)
                .overlay(alignment: .topLeading) {
                    PoseMotionChip(cue: cue, background: PeekTheme.surface)
                        .padding()
                }
                .frame(width: picture.width, height: picture.height)
                .position(x: picture.midX, y: picture.midY)
            Rectangle()
                .strokeBorder(accent, lineWidth: 5)
                .accessibilityHidden(true)
        }
        .background(PeekTheme.cameraChrome)
        .ignoresSafeArea()
    }
}
