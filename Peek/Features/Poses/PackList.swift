import SwiftUI

/// The pack tiles, one below the other. A tap selects the pack.
struct PackList: View {
    let packs: [PosePack]
    let onSelect: (PosePack) -> Void

    var body: some View {
        VStack {
            ForEach(packs) { pack in
                Button { onSelect(pack) } label: {
                    PackTile(pack: pack)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
