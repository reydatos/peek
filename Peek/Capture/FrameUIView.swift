import AVFoundation
import UIKit

final class FrameUIView: UIView {
    override static var layerClass: AnyClass {
        AVSampleBufferDisplayLayer.self
    }

    private var displayLayer: AVSampleBufferDisplayLayer {
        // `layerClass` makes this cast always succeed.
        // swiftlint:disable:next force_cast
        layer as! AVSampleBufferDisplayLayer
    }

    private let capture: any CaptureProviding
    private var rotationObserver: RotationObserver?
    private var observedDeviceID: String?

    init(capture: any CaptureProviding) {
        self.capture = capture
        super.init(frame: .zero)
        displayLayer.videoGravity = .resizeAspect
        capture.frameSource.attach(displayLayer.sampleBufferRenderer)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func detach() {
        capture.frameSource.detach(displayLayer.sampleBufferRenderer)
    }

    func observeRotation(deviceID: String?) {
        guard deviceID != observedDeviceID else { return }
        observedDeviceID = deviceID
        rotationObserver = deviceID
            .flatMap { AVCaptureDevice(uniqueID: $0) }
            .map { device in
                RotationObserver(device: device, layer: displayLayer) { [capture] angle in
                    Task { await capture.setFrameRotationAngle(angle) }
                }
            }
    }

    func setMirrored(_ isMirrored: Bool) {
        displayLayer.setAffineTransform(isMirrored ? CGAffineTransform(scaleX: -1, y: 1) : .identity)
    }
}
