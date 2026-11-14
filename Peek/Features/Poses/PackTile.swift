import SwiftUI

/// One pack in a list: a small instant photo, a narrow accent bar, the name, and one line about the pack.
/// A selected tile has a check and a border in the strong color. Other tiles have a chevron.
struct PackTile: View {
    let pack: PosePack
    var isSelected = false
    @ScaledMetric(relativeTo: .title3) private var barWidth = 6
    @ScaledMetric(relativeTo: .title3) private var barHeight = 44

    var body: some View {
        HStack {
            if let cue = pack.cues.first {
                InstantThumbnail(cue: cue)
            }
            Capsule()
                .fill(pack.accent)
                .frame(width: barWidth, height: barHeight)
                .accessibilityHidden(true)
            VStack(alignment: .leading) {
                Text(pack.name)
                    .font(.headline)
                Text(pack.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(PeekTheme.inkSecondary)
            }
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "chevron.right")
                .font(isSelected ? .title3 : .footnote)
                .accessibilityHidden(true)
        }
        .padding()
        .foregroundStyle(PeekTheme.ink)
        .background(PeekTheme.surface, in: .rect(cornerRadius: PeekTheme.cardCorner))
        .overlay {
            RoundedRectangle(cornerRadius: PeekTheme.cardCorner)
                .strokeBorder(isSelected ? PeekTheme.strong : PeekTheme.separator, lineWidth: isSelected ? 2 : 1)
        }
        .contentShape(.rect(cornerRadius: PeekTheme.cardCorner))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    VStack {
        PackTile(pack: PoseLibrary.packs[1])
        PackTile(pack: PoseLibrary.packs[2], isSelected: true)
    }
    .padding()
    .background(PeekTheme.page)
}
