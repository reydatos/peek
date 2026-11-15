import AVFoundation
import SwiftUI

/// A live preview of the shared capture session. Each display has its own instance.
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    let deviceID: String?
    let isMirrored: Bool
    /// True when the picture covers the view and the overflow is cut. False shows the full frame.
    var fillsView = false

    func makeUIView(context _: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        return view
    }

    func updateUIView(_ view: PreviewUIView, context _: Context) {
        view.previewLayer.videoGravity = fillsView ? .resizeAspectFill : .resizeAspect
        view.observeRotation(deviceID: deviceID)
        view.setMirrored(isMirrored)
    }
}
