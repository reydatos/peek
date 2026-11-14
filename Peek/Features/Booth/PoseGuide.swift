import SwiftUI

/// A small copy of the pose reference, in the corner of the live photo. It shows during live framing only.
struct PoseGuide: View {
    let cue: PoseCue
    let accent: Color
    /// The large form is for one screen: the people in the photo read it at portrait distance.
    var isLarge = false
    @ScaledMetric(relativeTo: .body) private var height = 55

    var body: some View {
        PoseReferenceFrame(cue: cue, accent: accent, cornerRadius: PeekTheme.slotCorner)
            .frame(height: isLarge ? height * 2 : height)
    }
}
