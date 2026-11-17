import SwiftUI

@main
struct PeekApp: App {
    @State private var savedPoses = SavedPoses(store: DefaultsSavedPoseStore())
    /// The built-in packs and the packs of the customer.
    @State private var catalog: PoseCatalog
    @State private var userPacks: UserPacks
    @State private var packImport: PackImport

    init() {
        let catalog = PoseCatalog()
        _catalog = State(initialValue: catalog)
        let userPacks = UserPacks(catalog: catalog, store: UserPackStore.shared)
        _userPacks = State(initialValue: userPacks)
        _packImport = State(initialValue: PackImport(userPacks: userPacks))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if userPacks.isLoaded {
                    // The app opens on the viewfinder (owner decision, 2026-11-15). There is no Home screen.
                    // A set that is not complete comes back from storage; with no such set, the classic booth starts.
                    BoothView(request: BoothRequest(packID: PoseLibrary.classicID, resumesDraft: true), catalog: catalog)
                } else {
                    // The booth starts after the packs of the customer are read, so a stored set finds its pack.
                    PeekTheme.page.ignoresSafeArea()
                }
            }
            .tint(PeekTheme.ink)
            .environment(savedPoses)
            .environment(catalog)
            .environment(userPacks)
            .environment(packImport)
            // A pack file from AirDrop, Messages, Mail, or Files. The customer confirms before the app adds the pack.
            .onOpenURL { url in
                Task { await packImport.open(url) }
            }
            .modifier(PackImportAlerts())
            .task { await userPacks.load() }
        }
    }
}
