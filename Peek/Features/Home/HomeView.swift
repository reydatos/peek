import SwiftUI

/// The first screen: start a classic booth, resume the draft, or choose a Copycat pack. Lookbook page 01.
///
/// The camera starts in the booth, not here. So the system asks for camera access after an explicit action.
struct HomeView: View {
    @State private var request: BoothRequest?
    @State private var packToConfirm: PosePack?
    @State private var hasDraft = false
    /// True on a display that is wider than tall, such as an open iPhone Duo.
    @State private var isWide = false

    var body: some View {
        let layout = isWide ? AnyLayout(HStackLayout(alignment: .top)) : AnyLayout(VStackLayout())
        ScrollView {
            layout {
                HomeBoothCard(
                    hasDraft: hasDraft,
                    onStart: { start(PoseLibrary.packs[0]) },
                    onResume: { request = BoothRequest(packID: PoseLibrary.classicID, resumesDraft: true) }
                )
                HomeCopycatCard(onSelect: start)
            }
            .padding()
        }
        .background(PeekTheme.ink)
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
    .preferredColorScheme(.dark)
}
