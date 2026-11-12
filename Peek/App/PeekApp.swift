import SwiftUI

@main
struct PeekApp: App {
    var body: some Scene {
        WindowGroup {
            // The app opens in the booth. There is no home screen.
            NavigationStack {
                BoothView(packID: PoseLibrary.classicID)
            }
        }
    }
}
