import Foundation

/// The action of the booth that leaves the session: open the pose browser.
/// The booth is the first screen of the app, so it has no close action.
struct BoothActions {
    let showPoses: () -> Void
}
