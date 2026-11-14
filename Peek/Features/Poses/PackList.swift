import SwiftUI

/// The pack tiles, one below the other. A tap selects the pack.
struct PackList: View {
    let packs: [PosePack]
    /// The pack that has the selected look. Nil in a list where a tap opens the pack at once.
    var selectedID: String?
    let onSelect: (PosePack) -> Void

    var body: some View {
        VStack {
            ForEach(packs) { pack in
                Button { onSelect(pack) } label: {
                    PackTile(pack: pack, isSelected: pack.id == selectedID)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
