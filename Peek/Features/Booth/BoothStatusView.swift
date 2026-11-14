import SwiftUI
import UIKit

/// Shows the stage when the camera runs, or a recovery message when it does not.
struct BoothStatusView: View {
    let model: BoothSessionModel
    /// False in the wide booth: the leading panel shows the pose reference there.
    var showsPoseArt = true
    /// True on a tall display: the photo runs edge to edge, and the camera bar has the cue line.
    var isFullBleed = false

    var body: some View {
        switch model.cameraStatus {
        case .idle, .starting:
            ProgressView()
        case .running:
            BoothStageView(
                model: model,
                isSubjectFacing: !model.isOuterDisplayPresenting,
                showsPoseArt: showsPoseArt,
                isFullBleed: isFullBleed
            )
        case .denied:
            ContentUnavailableView {
                Label(.cameraDeniedTitle, systemImage: "camera")
            } description: {
                Text(.cameraDeniedMessage)
            } actions: {
                if let settings = URL(string: UIApplication.openSettingsURLString) {
                    Link(destination: settings) { Text(.openSettings) }
                }
            }
        case .unavailable:
            ContentUnavailableView {
                Label(.cameraUnavailableTitle, systemImage: "camera")
            } description: {
                Text(.cameraUnavailableMessage)
            }
        case .failed:
            ContentUnavailableView {
                Label(.cameraFailedTitle, systemImage: "exclamationmark.triangle")
            } description: {
                Text(.cameraFailedMessage)
            }
        }
    }
}
