import SwiftUI

/// The pose library: Discover has the poses in groups, one for each pack. Saved has the poses with a star.
/// It stays on the photographer's side, outside the live session.
struct PoseLibraryView: View {
    /// Opens a booth with the pack.
    let onSelect: (PosePack) -> Void
    @Environment(SavedPoses.self) private var saved
    @State private var showsSaved = false
    @ScaledMetric(relativeTo: .body) private var cardWidth = 120

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    PeekSegmentedChoice(selection: $showsSaved, options: [(false, .discover), (true, .saved)])
                    if showsSaved {
                        savedPoses
                    } else {
                        ForEach(PoseLibrary.packs) { pack in
                            section(pack)
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

    private func section(_ pack: PosePack) -> some View {
        VStack(alignment: .leading) {
            Button { onSelect(pack) } label: {
                PackTile(pack: pack)
            }
            .buttonStyle(.plain)
            ScrollView(.horizontal) {
                HStack(alignment: .top) {
                    ForEach(pack.cues) { cue in
                        PoseCard(cue: cue, caption: pack.subtitle)
                            .frame(width: cardWidth)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.bottom)
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
