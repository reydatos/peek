import SwiftUI

/// The first screen: choose the classic booth or a Copycat pack, then start. Or resume the draft.
/// `docs/design/DESIGN.md`, screen 1. The classic booth is selected first.
///
/// The camera starts in the booth, not here. So the system asks for camera access after an explicit action.
struct HomeView: View {
    @State private var request: BoothRequest?
    @State private var packToConfirm: PosePack?
    @State private var hasDraft = false
    @State private var isCopycat = false
    /// The Copycat pack that Start a Booth opens.
    @State private var copycatID = PoseLibrary.copycatPacks.first?.id
    /// True on a display that is wider than tall, such as an open iPhone Duo.
    @State private var isWide = false

    var body: some View {
        let layout = isWide ? AnyLayout(HStackLayout(alignment: .top)) : AnyLayout(VStackLayout())
        ScrollView {
            layout {
                HomeBoothCard(
                    isCopycat: $isCopycat,
                    pack: selectedPack,
                    hasDraft: hasDraft,
                    onStart: { start(selectedPack) },
                    onResume: { request = BoothRequest(packID: PoseLibrary.classicID, resumesDraft: true) }
                )
                // A wide display shows the packs at all times, on the other side of the fold.
                if isWide || isCopycat {
                    HomeCopycatCard(selectedID: isCopycat ? copycatID : nil) { pack in
                        copycatID = pack.id
                        isCopycat = true
                    }
                }
            }
            .padding()
        }
        .background(PeekTheme.page)
        .onGeometryChange(for: Bool.self) { $0.size.width > $0.size.height } action: { isWide = $0 }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $request) { request in
            BoothView(request: request)
        }
        // A new booth discards the draft, so the photographer confirms first.
        .confirmationDialog(
            Text(.discardShotsTitle),
            isPresented: Binding(
                get: { packToConfirm != nil },
                set: {
                    if !$0 {
                        packToConfirm = nil
                    }
                }
            ),
            titleVisibility: .visible,
            presenting: packToConfirm
        ) { pack in
            Button(role: .destructive) { open(pack) } label: { Text(.discardShots) }
            Button(role: .cancel) {} label: { Text(.cancel) }
        } message: { _ in
            Text(.discardShotsMessage)
        }
        .task(id: request) {
            // This runs again when the booth closes, so "Resume Draft" follows the storage.
            if request == nil {
                hasDraft = await BoothDraftStore.hasDraft()
            }
        }
    }

    private var selectedPack: PosePack {
        let copycat = PoseLibrary.copycatPacks.first { $0.id == copycatID }
        return (isCopycat ? copycat : nil) ?? PoseLibrary.packs[0]
    }

    private func start(_ pack: PosePack) {
        if hasDraft {
            packToConfirm = pack
        } else {
            open(pack)
        }
    }

    private func open(_ pack: PosePack) {
        packToConfirm = nil
        request = BoothRequest(packID: pack.id, resumesDraft: false)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
