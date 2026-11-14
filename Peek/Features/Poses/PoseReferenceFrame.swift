import SwiftUI

/// The pose reference in a frame of the pack accent. The frame and its label show that this is not the live camera.
struct PoseReferenceFrame: View {
    let cue: PoseCue
    let accent: Color
    var lineWidth: CGFloat = 3
    var cornerRadius = PeekTheme.thumbnailCorner
    var showsMove = false

    var body: some View {
        PoseArt(cue: cue, cornerRadius: cornerRadius, showsMove: showsMove)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(accent, lineWidth: lineWidth)
            }
    }
}
