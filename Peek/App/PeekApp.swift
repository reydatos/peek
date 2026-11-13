import SwiftUI

@main
struct PeekApp: App {
    init() {
        PeekFont.register()
    }

    var body: some Scene {
        WindowGroup {
            // The app opens in the booth. There is no home screen.
            NavigationStack {
                BoothView(packID: PoseLibrary.classicID)
            }
            .font(PeekFont.sans(.body))
            .preferredColorScheme(.dark)
            .tint(PeekTheme.cream)
        }
    }
}
