import SwiftUI
import UIKit

/// The pose picture across the outer display, with the live frame small at the lower right.
///
/// The people in the photo copy the picture and check themselves in the small frame. There is no pose name here.
struct OuterPoseStage: View {
    let cue: PoseCue
    let picture: UIImage
    let model: BoothSessionModel
    let isMirrored: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // The full picture stays inside the safe area, so the camera housing hides no part of the pose.
            Image(uiImage: picture)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel(Text(cue.name))
            FramePreviewView(capture: model.capture, deviceID: model.deviceID, isMirrored: isMirrored)
                // The same 4:3 crop as the shot, so the people see how the shot frames them.
                .aspectRatio(4 / 3, contentMode: .fit)
                .containerRelativeFrame(.horizontal, count: 5, span: 2, spacing: 0)
                .clipShape(.rect(cornerRadius: PeekTheme.smallCorner))
                .padding()
                .accessibilityLabel(Text(.livePreview))
        }
        .background {
            // A soft copy of the picture fills the screen edge to edge behind the full picture.
            PeekTheme.ink
                .overlay {
                    Image(uiImage: picture)
                        .resizable()
                        .scaledToFill()
                        .blur(radius: 24)
                }
                .clipped()
                .ignoresSafeArea()
                .accessibilityHidden(true)
        }
    }
}
