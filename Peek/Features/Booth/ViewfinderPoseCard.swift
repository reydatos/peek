import SwiftUI

/// The pose reference and its name as one card, in a corner of the viewfinder of a tall display.
struct ViewfinderPoseCard: View {
    let cue: PoseCue
    let accent: Color
    /// The large form is for one screen: the people in the photo read it at portrait distance.
    var isLarge = false
    @ScaledMetric(relativeTo: .body) private var height = 55

    var body: some View {
        VStack(spacing: PeekTheme.tightSpace) {
            PoseReferenceFrame(cue: cue, accent: accent, cornerRadius: PeekTheme.slotCorner)
                .frame(height: isLarge ? height * 2 : height)
            Text(cue.name)
                .font(.caption)
                .bold()
                .foregroundStyle(PeekTheme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(PeekTheme.tightSpace)
        .background(PeekTheme.surface, in: .rect(cornerRadius: PeekTheme.smallPhotoCorner))
        .accessibilityElement(children: .combine)
    }
}
