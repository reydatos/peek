import SwiftUI

/// One pack in the pose library: its poses as one block of small pictures, with the name and one line below.
/// A tap on the card selects the pack. The cards are in a grid, so the packs show together with little scroll.
struct PackCard: View {
    let pack: PosePack

    var body: some View {
        VStack(alignment: .leading) {
            // Two pictures in each row. A pack has three or four poses.
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: PeekTheme.tightSpace) {
                ForEach(pack.cues.prefix(4)) { cue in
                    PoseArt(cue: cue, cornerRadius: PeekTheme.slotCorner)
                        .accessibilityHidden(true)
                }
            }
            Text(pack.name)
                .font(.headline)
                .foregroundStyle(PeekTheme.ink)
            Text(pack.subtitle)
                .font(.caption)
                .foregroundStyle(PeekTheme.inkSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(PeekTheme.tightSpace * 2)
        .background(PeekTheme.surface, in: .rect(cornerRadius: PeekTheme.cardCorner))
        .overlay {
            RoundedRectangle(cornerRadius: PeekTheme.cardCorner)
                .strokeBorder(pack.accent, lineWidth: 2)
        }
        .contentShape(.rect(cornerRadius: PeekTheme.cardCorner))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    HStack {
        PackCard(pack: PoseLibrary.packs[0])
        PackCard(pack: PoseLibrary.packs[2])
    }
    .padding()
    .background(PeekTheme.page)
}
