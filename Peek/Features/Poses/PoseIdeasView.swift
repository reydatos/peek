import SwiftUI

/// The pack browser inside the booth. It stays on the photographer's side, outside the live session.
struct PoseIdeasView: View {
    let onSelect: (PosePack) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                PackList(packs: PoseLibrary.packs, onSelect: onSelect)
                    .padding()
            }
            .background(PeekTheme.page)
            .navigationTitle(Text(.poseIdeas))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    PoseIdeasView { _ in }
}
