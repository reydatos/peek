import SwiftUI

/// The pose reference for the people in the photo. The complete picture shows, with no cut, as large as the
/// outer display permits. It is at the far right, because the hinge cover of an open iPhone Duo is at the left.
///
/// The picture is 3:4 and the display has a different shape, so the complete picture can not cover the display.
/// The background of the picture continues to the edges of the display: the line of pixels at each edge of the
/// picture is drawn across the space beside that edge. So the people see one picture that covers the screen,
/// with nothing cut (owner decision, 2026-11-15).
///
/// That is correct only for a picture with plain edges, as the cartoon and 3D pose pictures have. A photo pose
/// picture has no plain edge, so it has a wide copy (`PoseCue.wideAssetName`) with the person at the right. The
/// wide copy covers the display. A photo with no wide copy shows complete, with black beside it.
///
/// The display is used to its edges: the view does not stop at the safe area, and the placement keeps the
/// complete picture clear of the occluded areas that the system reports.
///
/// The frame of the pack accent is around the display. It shows that this is not the live camera. The picture has
/// no "Pose reference" label and no pose name on it. The motion label of an animated pose is on the picture.
struct OuterReferenceStage: View {
    let cue: PoseCue
    let accent: Color

    var body: some View {
        GeometryReader { proxy in
            if let wide = cue.widePicture, wide.size.height > 0 {
                // A photo pose picture has a wide copy with the person at the right. It covers the display, with
                // its right edge at the right edge of the display, so the person stays in view.
                let frame = StripPlacement.rightPinnedFill(in: proxy.size, aspect: wide.size.width / wide.size.height)
                Image(uiImage: wide)
                    .resizable()
                    .frame(width: frame.width, height: frame.height)
                    .position(x: frame.midX, y: frame.midY)
                    .accessibilityLabel(cue.name.text)
            } else {
                fitted(in: proxy)
            }
            Rectangle()
                .strokeBorder(accent, lineWidth: 5)
                .accessibilityHidden(true)
        }
        .clipped()
        .background(PeekTheme.cameraChrome)
        .ignoresSafeArea()
    }

    /// The complete 3:4 picture, with its background continued to the edges of the display when its edges are plain.
    @ViewBuilder private func fitted(in proxy: GeometryProxy) -> some View {
        let picture = StripPlacement.outerColumn(in: proxy.size, avoiding: proxy.occlusions)
        let image = cue.picture
        let bands = Self.bands(around: picture, in: proxy.size)
        // The background of a picture with plain edges continues to the edges of the display.
        // A photo has no plain edge. It shows complete on black: to cover the display, the display must cut
        // the head or the feet, and a pose reference needs the two.
        let isExtended = image.map { image in bands.allSatisfy { $0.0.isPlain(in: image) } } ?? false
        if isExtended, let image {
            ForEach(bands, id: \.0) { edge, band in
                if let strip = edge.strip(of: image) {
                    Image(uiImage: strip)
                        .resizable()
                        .frame(width: band.width, height: band.height)
                        .position(x: band.midX, y: band.midY)
                        .accessibilityHidden(true)
                }
            }
        }
        PoseArt(cue: cue, cornerRadius: 0, showsMove: true)
            .frame(width: picture.width, height: picture.height)
            .position(x: picture.midX, y: picture.midY)
        // The motion label is in the frame that stays in view.
        PoseMotionChip(cue: cue, background: PeekTheme.surface)
            .padding()
            .frame(width: picture.width, height: picture.height, alignment: .topLeading)
            .position(x: picture.midX, y: picture.midY)
    }

    /// The spaces between the picture and the edges of the display, each with the edge of the picture beside it.
    private static func bands(around picture: CGRect, in display: CGSize) -> [(PictureEdge, CGRect)] {
        [
            (PictureEdge.left, CGRect(x: 0, y: picture.minY, width: picture.minX, height: picture.height)),
            (.right, CGRect(x: picture.maxX, y: picture.minY, width: display.width - picture.maxX, height: picture.height)),
            (.top, CGRect(x: 0, y: 0, width: display.width, height: picture.minY)),
            (.bottom, CGRect(x: 0, y: picture.maxY, width: display.width, height: display.height - picture.maxY)),
        ]
        .filter { $0.1.width > 0 && $0.1.height > 0 }
    }
}
