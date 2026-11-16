import SwiftUI

/// The pose library: Discover has a grid of the packs, and a tap selects a pack. Saved has the poses with a star.
/// The grid replaces a long list with a row of poses for each pack (owner decision, 2026-11-15). The star that
/// saves a pose is on the pose tray of the booth.
/// It stays on the photographer's side, outside the live session.
struct PoseLibraryView: View {
    /// Opens a booth with the pack.
    let onSelect: (PosePack) -> Void
    @Environment(SavedPoses.self) private var saved
    @State private var showsSaved = false
    @ScaledMetric(relativeTo: .body) private var cardWidth = 120
    /// The least width of a pack card: two small pose pictures side by side. This is a design value.
    @ScaledMetric(relativeTo: .body) private var packWidth = 150

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    PeekSegmentedChoice(selection: $showsSaved, options: [(false, .discover), (true, .saved)])
                    if showsSaved {
                        savedPoses
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: packWidth), alignment: .top)]) {
                            ForEach(PoseLibrary.packs) { pack in
                                Button { onSelect(pack) } label: {
                                    PackCard(pack: pack)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(PeekTheme.page)
            .navigationTitle(Text(.poseIdeas))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder private var savedPoses: some View {
        if saved.cues.isEmpty {
            ContentUnavailableView {
                Label(.saved, systemImage: "star")
            } description: {
                Text(.noSavedPoses)
            }
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: cardWidth), alignment: .top)]) {
                ForEach(saved.cues) { cue in
                    PoseCard(cue: cue, caption: PoseLibrary.pack(for: cue.id)?.name ?? .poseIdeas)
                }
            }
        }
    }
}

#Preview {
    PoseLibraryView { _ in }
        .environment(SavedPoses())
}
