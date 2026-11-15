import AVFoundation
import SwiftUI

/// A live preview of the shared capture session. Each display has its own instance.
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    let deviceID: String?
    let isMirrored: Bool
    /// Receives the aspect (width / height) of the live picture, so the caller can give the picture its shape.
    var onAspect: (CGFloat) -> Void = { _ in }

    func makeUIView(context _: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspect
        return view
    }

    func updateUIView(_ view: PreviewUIView, context _: Context) {
        view.onAspect = onAspect
        view.observeRotation(deviceID: deviceID)
        view.setMirrored(isMirrored)
    }
}
