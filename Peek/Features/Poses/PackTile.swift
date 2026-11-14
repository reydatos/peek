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
                    .font(PeekFont.sans(.title3))
                Text(pack.subtitle)
                    .font(PeekFont.sans(.subheadline))
                    .foregroundStyle(PeekTheme.mist)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(PeekFont.sans(.footnote))
                .accessibilityHidden(true)
        }
        .padding()
        .foregroundStyle(Color.white)
        .background(PeekTheme.panel, in: .rect(cornerRadius: PeekTheme.corner))
        .contentShape(.rect(cornerRadius: PeekTheme.corner))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    PackTile(pack: PoseLibrary.packs[1])
        .padding()
        .background(PeekTheme.ink)
}
