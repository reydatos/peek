import SwiftUI

/// One pose in the library: the picture as a photo card, with the name and one line below it.
struct PoseCard: View {
    let cue: PoseCue
    let caption: LocalizedStringResource

    var body: some View {
        VStack(alignment: .leading) {
            PoseArt(cue: cue, cornerRadius: PeekTheme.smallPhotoCorner)
                .overlay(alignment: .topTrailing) {
                    SaveStarButton(cue: cue)
                }
            Text(cue.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(PeekTheme.ink)
            Text(caption)
                .font(.caption)
                .foregroundStyle(PeekTheme.inkSecondary)
        }
    }
}
