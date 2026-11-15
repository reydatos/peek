import AVFoundation
import UIKit

/// Keeps the one preview view of the inner display for the life of a booth.
///
/// The session gets its preview layer one time. A new preview layer on a session that runs makes the session
/// build its graph again, and the call waits on the main thread. On a physical iPhone Duo, that wait was longer
/// than 5 seconds when the booth changed from the tall layout to the wide layout at an unfold, and the system
/// stopped the app (2026-11-15).
final class PreviewHolder {
    private var view: PreviewUIView?

    /// The preview view of the session. The first call makes it; each later call gives the same view.
    func view(for session: AVCaptureSession) -> PreviewUIView {
        if let view {
            return view
        }
        let view = PreviewUIView()
        view.previewLayer.session = session
        // The picture covers the view. The caller gives the view the shape of the picture that it wants.
        view.previewLayer.videoGravity = .resizeAspectFill
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view = view
        return view
    }
}
