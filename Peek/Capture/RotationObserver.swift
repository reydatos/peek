import AVFoundation

/// Keeps one preview layer level with the horizon. On iPhone Duo the angle also changes
/// when the app moves between displays.
final class RotationObserver {
    private let coordinator: AVCaptureDevice.RotationCoordinator
    private let previewLayer: AVCaptureVideoPreviewLayer
    private var observation: NSKeyValueObservation?

    init(device: AVCaptureDevice, previewLayer: AVCaptureVideoPreviewLayer) {
        coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
        self.previewLayer = previewLayer
        observation = coordinator.observe(
            \.videoRotationAngleForHorizonLevelPreview,
            options: [.initial, .new]
        ) { [weak self] coordinator, _ in
            let angle = coordinator.videoRotationAngleForHorizonLevelPreview
            Task { @MainActor in self?.apply(angle) }
        }
    }

    private func apply(_ angle: CGFloat) {
        guard let connection = previewLayer.connection, connection.isVideoRotationAngleSupported(angle) else { return }
        connection.videoRotationAngle = angle
    }
}
