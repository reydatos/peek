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
    /// Receives the aspect (width / height) of the live picture, each time the rotation changes.
    var onAspect: (CGFloat) -> Void = { _ in }

    func observeRotation(deviceID: String?) {
        guard deviceID != observedDeviceID else { return }
        observedDeviceID = deviceID
        rotationObserver = deviceID
            .flatMap { AVCaptureDevice(uniqueID: $0) }
            .map { device in
                RotationObserver(device: device, layer: previewLayer) { [weak self, previewLayer] angle in
                    guard let connection = previewLayer.connection, connection.isVideoRotationAngleSupported(angle)
                    else { return }
                    connection.videoRotationAngle = angle
                    let sensor = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
                    self?.onAspect(
                        PreviewAspect.aspect(sensorWidth: sensor.width, sensorHeight: sensor.height, rotationAngle: angle)
                    )
                }
            }
    }

    func setMirrored(_ isMirrored: Bool) {
        guard let connection = previewLayer.connection, connection.isVideoMirroringSupported else { return }
        // Assigning `isVideoMirrored` raises an exception while automatic adjustment stays on.
        connection.automaticallyAdjustsVideoMirroring = false
        connection.isVideoMirrored = isMirrored
    }
}
