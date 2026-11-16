import SwiftUI

/// The pose library: a grid of the packs, and a tap selects a pack. The poses button of the booth opens it.
///
/// The cards are in the order of their groups, and a filter shows one group (owner decision, 2026-11-15).
/// The grid replaces a long list with a row of poses for each pack, and the pose tray of the booth.
struct PoseLibraryView: View {
    /// Opens a booth with the pack.
    let onSelect: (PosePack) -> Void
    @Environment(PoseCatalog.self) private var catalog
    @State private var filter = PackFilter.all
    /// The least width of a pack card: two small pose pictures side by side. This is a design value.
    @ScaledMetric(relativeTo: .body) private var packWidth = 150

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    PeekSegmentedChoice(selection: $filter, options: filters)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: packWidth), alignment: .top)]) {
                        ForEach(catalog.packs(for: filter)) { pack in
                            Button { onSelect(pack) } label: {
                                PackCard(pack: pack)
                            }
                            .buttonStyle(.plain)
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

    /// The choices of the filter. "Mine" shows only when the customer has a pack.
    private var filters: [(value: PackFilter, label: LocalizedStringResource)] {
        let mine: [(value: PackFilter, label: LocalizedStringResource)] =
            catalog.packs(for: .only(.mine)).isEmpty ? [] : [(.only(.mine), .filterMine)]
        return [(.all, .filterAll)] + mine + [
            (.only(.kids), .filterKids),
            (.only(.street), .filterStreet),
            (.only(.trends), .filterTrends),
        ]
    }
}

#Preview {
    PoseLibraryView { _ in }
        .environment(PoseCatalog())
}
