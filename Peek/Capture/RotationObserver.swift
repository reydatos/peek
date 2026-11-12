import AVFoundation

/// Reports the angle that keeps one layer's video level with the horizon. On iPhone Duo the
/// angle also changes when the app moves between displays.
final class RotationObserver {
    private let coordinator: AVCaptureDevice.RotationCoordinator
    private let onChange: (CGFloat) -> Void
    private var observation: NSKeyValueObservation?

    init(device: AVCaptureDevice, layer: CALayer, onChange: @escaping (CGFloat) -> Void) {
        coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: layer)
        self.onChange = onChange
        observation = coordinator.observe(
            \.videoRotationAngleForHorizonLevelPreview,
            options: [.initial, .new]
        ) { [weak self] coordinator, _ in
            let angle = coordinator.videoRotationAngleForHorizonLevelPreview
            Task { @MainActor in self?.onChange(angle) }
        }
    }
}
