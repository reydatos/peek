import SwiftUI

/// The Copycat packs. Pack selection stays on the photographer's side.
struct HomeCopycatCard: View {
    let onSelect: (PosePack) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(.copycat)
                .font(PeekFont.sans(.largeTitle))
                .foregroundStyle(Color.white)
            PackList(packs: PoseLibrary.copycatPacks, onSelect: onSelect)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
