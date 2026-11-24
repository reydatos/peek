import SwiftUI

/// One pack in the pose library: its poses as one block of small pictures, with the name and one line below.
/// A tap on the card selects the pack. The cards are in a grid, so the packs show together with little scroll.
struct PackCard: View {
    let pack: PosePack
    /// The lock state of a paid pack (3A). A free pack has no chip.
    var lock = PackLock.none

    var body: some View {
        VStack(alignment: .leading) {
            // Two pictures in each row. A pack has three or four poses.
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: PeekTheme.tightSpace) {
                ForEach(pack.cues.prefix(4)) { cue in
                    PoseArt(cue: cue, cornerRadius: PeekTheme.slotCorner)
                        .accessibilityHidden(true)
                }
            }
            .overlay(alignment: .topLeading) {
                lockMark
                    .padding(PeekTheme.tightSpace)
            }
            pack.name.text
                .font(.headline)
                .foregroundStyle(PeekTheme.ink)
            pack.subtitle.text
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

    /// A locked pack shows a lock and the word "LOCKED", never color alone (3A). An owned pack shows a check.
    @ViewBuilder private var lockMark: some View {
        switch lock {
        case .none:
            EmptyView()
        case .locked:
            PeekChip(text: .packLocked, systemImage: "lock.fill")
        case .unlocked:
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .symbolRenderingMode(.palette)
                .foregroundStyle(PeekTheme.ink, PeekTheme.surface)
                .accessibilityLabel(Text(.packUnlocked))
        }
    }
}

/// The lock state of a pack card.
enum PackLock {
    /// A free pack, or a paid pack before the owned products are read.
    case none
    case locked
    case unlocked
}

#Preview {
    HStack {
        PackCard(pack: PoseLibrary.packs[0], lock: .locked)
        PackCard(pack: PoseLibrary.packs[2], lock: .unlocked)
    }
    .padding()
    .background(PeekTheme.page)
}
