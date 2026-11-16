import SwiftUI

@main
struct PeekApp: App {
    @State private var savedPoses = SavedPoses(store: DefaultsSavedPoseStore())
    /// The built-in packs and the packs of the customer.
    @State private var catalog = PoseCatalog()

    var body: some Scene {
        WindowGroup {
            // The app opens on the viewfinder (owner decision, 2026-11-15). There is no Home screen.
            // A set that is not complete comes back from storage; with no such set, the classic booth starts.
            BoothView(request: BoothRequest(packID: PoseLibrary.classicID, resumesDraft: true), catalog: catalog)
                .tint(PeekTheme.ink)
                .environment(savedPoses)
                .environment(catalog)
        }
    }
}
