import Foundation

/// The actions of the booth that leave the session: close the booth, and open the pose browser.
struct BoothActions {
    let close: () -> Void
    let showPoses: () -> Void
}
