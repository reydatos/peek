import SwiftUI

/// One pack in a list: a thumbnail, a narrow color bar, the name, and one line about the pack. Lookbook page 01.
struct PackTile: View {
    let pack: PosePack
    @ScaledMetric(relativeTo: .title3) private var thumbnailHeight = 64
    @ScaledMetric(relativeTo: .title3) private var barWidth = 6

    var body: some View {
        HStack {
            if let cue = pack.cues.first {
                PoseArt(cue: cue)
                    .frame(height: thumbnailHeight)
                    .accessibilityHidden(true)
            }
            Capsule()
                .fill(pack.accent)
                .frame(width: barWidth, height: thumbnailHeight / 2)
                .accessibilityHidden(true)
            VStack(alignment: .leading) {
                Text(pack.name)
                    .font(.title3)
                Text(pack.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(PeekTheme.inkSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .accessibilityHidden(true)
        }
        .padding()
        .foregroundStyle(PeekTheme.ink)
        .background(PeekTheme.surface, in: .rect(cornerRadius: PeekTheme.cardCorner))
        .overlay {
            RoundedRectangle(cornerRadius: PeekTheme.cardCorner)
                .strokeBorder(PeekTheme.separator)
        }
        .contentShape(.rect(cornerRadius: PeekTheme.cardCorner))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    PackTile(pack: PoseLibrary.packs[1])
        .padding()
        .background(PeekTheme.page)
}
