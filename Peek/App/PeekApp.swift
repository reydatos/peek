import SwiftUI

@main
struct PeekApp: App {
    @State private var savedPoses = SavedPoses(store: DefaultsSavedPoseStore())
    /// The built-in packs and the packs of the customer.
    @State private var catalog: PoseCatalog
    @State private var userPacks: UserPacks
    @State private var packImport: PackImport
    /// What the customer owns. Its transaction listener starts at launch.
    @State private var entitlements = Entitlements(client: AppStoreClient())
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // No pack draft exists when the app opens, so each clip in the temporary folder has no owner.
        Task.detached { StaleClips.remove() }
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
                    // A set that is not complete comes back from storage; with no such set, the free pack starts.
                    BoothView(request: BoothRequest(packID: PoseLibrary.freeID, resumesDraft: true), catalog: catalog)
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
            .environment(entitlements)
            // A pack file from AirDrop, Messages, Mail, or Files. The customer confirms before the app adds the pack.
            .onOpenURL { url in
                Task { await packImport.open(url) }
            }
            .modifier(PackImportAlerts())
            .task { await userPacks.load() }
            // An Ask to Buy approval, a renewal, or a refund that came while the app was closed arrives at launch.
            .task { await entitlements.start() }
            // Coming back to the app reads the owned products again, so an expiry is seen at the next pack choice.
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task { await entitlements.refresh() }
                }
            }
        }
    }
}
