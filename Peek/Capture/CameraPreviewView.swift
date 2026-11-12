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
        view.previewLayer.videoGravity = .resizeAspect
        return view
    }

    func updateUIView(_ view: PreviewUIView, context _: Context) {
        view.observeRotation(deviceID: deviceID)
        view.setMirrored(isMirrored)
    }
}
