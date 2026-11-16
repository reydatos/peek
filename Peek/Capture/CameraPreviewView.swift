import AVFoundation
import SwiftUI

/// The live preview of the shared capture session on the inner display.
///
/// Each layout of the booth makes its own container, but all containers show the one preview view of the holder.
/// So a change of layout, or the return from review, attaches no new preview layer to the session.
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    let holder: PreviewHolder
    let deviceID: String?
    let isMirrored: Bool
    /// `PreviewHolder.generation`. A new value makes this view take the preview back from another screen.
    var generation = 0

    func makeUIView(context _: Context) -> UIView {
        let container = UIView()
        mount(in: container)
        return container
    }

    func updateUIView(_ container: UIView, context _: Context) {
        // A container that went away later can not take the preview from this one: the preview comes back here.
        let preview = mount(in: container)
        preview.observeRotation(deviceID: deviceID)
        preview.setMirrored(isMirrored)
    }

    /// Puts the preview view in the container. A view has one parent, so it leaves its old container.
    @discardableResult private func mount(in container: UIView) -> PreviewUIView {
        let preview = holder.view(for: session)
        if preview.superview !== container {
            preview.frame = container.bounds
            container.addSubview(preview)
        }
        return preview
    }
}
