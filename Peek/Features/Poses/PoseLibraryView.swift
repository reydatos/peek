import SwiftUI

/// The pose library: a grid of the packs, and a tap selects a pack. The poses button of the booth opens it.
///
/// The cards are in the order of their groups, and a filter shows one group (owner decision, 2026-11-15).
/// The grid replaces a long list with a row of poses for each pack, and the pose tray of the booth.
struct PoseLibraryView: View {
    /// The pack of the set in progress, when that set has shots. A delete of this pack discards the shots.
    var packWithShotsID: String?
    /// Opens a booth with the pack.
    let onSelect: (PosePack) -> Void
    /// Opens the pack editor. With no action, the library has no "New pack" card.
    var onNewPack: (() -> Void)?
    /// Removes a pack of the customer, after the customer confirmed it.
    var onDelete: ((PosePack) -> Void)?
    @State private var packToDelete: PosePack?
    @State private var packToShare: PosePack?
    @State private var isImporting = false
    @Environment(PackImport.self) private var packImport: PackImport?
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
                        if let onNewPack, filter == .all || filter == .only(.mine) {
                            Button(action: onNewPack) {
                                NewPackCard()
                            }
                            .buttonStyle(.plain)
                        }
                        ForEach(catalog.packs(for: filter)) { pack in
                            Button { onSelect(pack) } label: {
                                PackCard(pack: pack)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                // The customer can send their own pack to a different phone.
                                if pack.category == .mine, packImport != nil {
                                    Button { packToShare = pack } label: {
                                        Label(.sharePack, systemImage: "square.and.arrow.up")
                                    }
                                }
                                // Only a pack of the customer can go away.
                                if pack.category == .mine, onDelete != nil {
                                    Button(role: .destructive) { packToDelete = pack } label: {
                                        Label(.deletePack, systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(PeekTheme.page)
            .navigationTitle(Text(.poseIdeas))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if packImport != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { isImporting = true } label: {
                            Label(.importPack, systemImage: "square.and.arrow.down")
                        }
                    }
                }
            }
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.peekPack]) { result in
                if case let .success(url) = result {
                    Task { await packImport?.open(url) }
                }
            }
            .sheet(item: $packToShare) { pack in
                PackShareView(pack: pack)
            }
            .modifier(PackImportAlerts())
            .confirmationDialog(
                Text(.deletePackTitle),
                isPresented: Binding(
                    get: { packToDelete != nil },
                    set: {
                        if !$0 {
                            packToDelete = nil
                        }
                    }
                ),
                titleVisibility: .visible,
                presenting: packToDelete
            ) { pack in
                Button(role: .destructive) {
                    onDelete?(pack)
                    packToDelete = nil
                } label: { Text(.deletePack) }
                Button(role: .cancel) {} label: { Text(.cancel) }
            } message: { pack in
                Text(pack.id == packWithShotsID ? .deletePackInUseMessage : .deletePackMessage)
            }
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
