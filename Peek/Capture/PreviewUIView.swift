import AVFoundation
import UIKit

final class PreviewUIView: UIView {
    override static var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        // `layerClass` makes this cast always succeed.
        // swiftlint:disable:next force_cast
        layer as! AVCaptureVideoPreviewLayer
    }

    private var rotationObserver: RotationObserver?
    private var observedDeviceID: String?

    func observeRotation(deviceID: String?) {
        guard deviceID != observedDeviceID else { return }
        observedDeviceID = deviceID
        rotationObserver = deviceID
            .flatMap { AVCaptureDevice(uniqueID: $0) }
            .map { RotationObserver(device: $0, previewLayer: previewLayer) }
    }

    func setMirrored(_ isMirrored: Bool) {
        guard let connection = previewLayer.connection, connection.isVideoMirroringSupported else { return }
        // Assigning `isVideoMirrored` raises an exception while automatic adjustment stays on.
        connection.automaticallyAdjustsVideoMirroring = false
        connection.isVideoMirrored = isMirrored
    }
}
