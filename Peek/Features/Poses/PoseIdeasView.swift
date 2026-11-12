import SwiftUI

/// The pack browser. It stays on the photographer's side, outside the live session.
struct PoseIdeasView: View {
    var body: some View {
        List(PoseLibrary.packs) { pack in
            PosePackSection(pack: pack)
        }
        .navigationTitle(Text(.poseIdeas))
    }
}

#Preview {
    NavigationStack {
        PoseIdeasView()
    }
}
