import AVFoundation
import SwiftUI

/// A live preview of the shared capture session. Each display has its own instance.
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    let deviceID: String?
    let isMirrored: Bool

    func makeUIView(context _: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        // The picture covers the view. The caller gives the view the shape of the picture that it wants.
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ view: PreviewUIView, context _: Context) {
        view.observeRotation(deviceID: deviceID)
        view.setMirrored(isMirrored)
    }
}
