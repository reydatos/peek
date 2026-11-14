import SwiftUI
import UIKit

/// The pose picture across the full outer display, with the live frame small at the lower right.
///
/// The people in the photo copy the picture and check themselves in the small frame. There is no pose name here.
struct OuterPoseStage: View {
    let cue: PoseCue
    let picture: UIImage
    let model: BoothSessionModel
    let isMirrored: Bool

    var body: some View {
        FramePreviewView(capture: model.capture, deviceID: model.deviceID, isMirrored: isMirrored)
            // The same 4:3 crop as the shot, so the people see how the shot frames them.
            .aspectRatio(4 / 3, contentMode: .fit)
            .containerRelativeFrame(.horizontal, count: 5, span: 2, spacing: 0)
            .clipShape(.rect(cornerRadius: PeekTheme.smallCorner))
            .padding()
            .accessibilityLabel(Text(.livePreview))
            // The small frame stays inside the safe area, clear of the camera housing.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .background {
                // The picture fills the display edge to edge. The display crops the sides of the picture.
                PeekTheme.ink
                    .overlay {
                        Image(uiImage: picture)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
                    .ignoresSafeArea()
                    .accessibilityLabel(Text(cue.name))
            }
    }
}
