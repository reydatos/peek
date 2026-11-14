import SwiftUI

@main
struct PeekApp: App {
    init() {
        PeekFont.register()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
            .font(PeekFont.sans(.body))
            .preferredColorScheme(.dark)
            .tint(PeekTheme.cream)
        }
    }
}
