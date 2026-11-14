import SwiftUI

/// The Copycat packs. A tap selects the pack; Start a Booth opens it. Pack selection stays on the photographer's side.
struct HomeCopycatCard: View {
    let selectedID: String?
    let onSelect: (PosePack) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(.copycat)
                .font(.title2)
                .bold()
                .foregroundStyle(PeekTheme.ink)
            PackList(packs: PoseLibrary.copycatPacks, selectedID: selectedID, onSelect: onSelect)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
