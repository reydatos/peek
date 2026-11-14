import SwiftUI

@main
struct PeekApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
            .tint(PeekTheme.ink)
        }
    }
}
