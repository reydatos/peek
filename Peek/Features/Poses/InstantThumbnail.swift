import SwiftUI

/// A small instant photo of a pose: the picture on photo paper, a little tilted. It is decoration for a pack tile.
struct InstantThumbnail: View {
    let cue: PoseCue
    @ScaledMetric(relativeTo: .title3) private var height = 56
    @ScaledMetric(relativeTo: .title3) private var border = 3

    var body: some View {
        PoseArt(cue: cue, cornerRadius: 2)
            .frame(height: height)
            .padding(border)
            .padding(.bottom, border * 2)
            .background(PeekTheme.photoPaper, in: .rect(cornerRadius: 4))
            .shadow(color: PeekTheme.scrim.opacity(0.3), radius: 4, y: 2)
            .rotationEffect(.degrees(-4))
            .accessibilityHidden(true)
    }
}
