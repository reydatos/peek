import SwiftUI

/// The first card of the pose library: it opens the pack editor, where the customer makes a pack.
struct NewPackCard: View {
    var body: some View {
        VStack(alignment: .leading) {
            PeekTheme.fill
                .aspectRatio(3 / 4, contentMode: .fit)
                .overlay {
                    Image(systemName: "plus")
                        .font(.largeTitle)
                        .foregroundStyle(PeekTheme.ink)
                        .accessibilityHidden(true)
                }
                .clipShape(.rect(cornerRadius: PeekTheme.slotCorner))
            Text(.newPack)
                .font(.headline)
                .foregroundStyle(PeekTheme.ink)
            Text(.newPackHint)
                .font(.caption)
                .foregroundStyle(PeekTheme.inkSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(PeekTheme.tightSpace * 2)
        .background(PeekTheme.surface, in: .rect(cornerRadius: PeekTheme.cardCorner))
        .overlay {
            RoundedRectangle(cornerRadius: PeekTheme.cardCorner)
                .strokeBorder(PeekTheme.separator, style: StrokeStyle(lineWidth: 2, dash: [6]))
        }
        .contentShape(.rect(cornerRadius: PeekTheme.cardCorner))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    NewPackCard()
        .frame(width: 180)
        .padding()
        .background(PeekTheme.page)
}
