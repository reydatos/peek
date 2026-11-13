import SwiftUI

/// The pack browser. It stays on the photographer's side, outside the live session.
struct PoseIdeasView: View {
    let onSelect: (PosePack) -> Void

    var body: some View {
        NavigationStack {
            List(PoseLibrary.packs) { pack in
                PosePackSection(pack: pack, onSelect: onSelect)
            }
            .scrollContentBackground(.hidden)
            .background(PeekTheme.ink)
            .navigationTitle(Text(.poseIdeas))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    PoseIdeasView { _ in }
}
