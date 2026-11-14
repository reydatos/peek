import SwiftUI

@main
struct PeekApp: App {
    @State private var savedPoses = SavedPoses(store: DefaultsSavedPoseStore())

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
            .tint(PeekTheme.ink)
            .environment(savedPoses)
        }
    }
}
