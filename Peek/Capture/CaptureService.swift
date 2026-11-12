import AVFoundation

/// Owns the one capture session. PRD FR-02: one verified rear-camera configuration.
actor CaptureService: CaptureProviding {
    nonisolated(unsafe) let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var device: AVCaptureDevice?
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var inFlight: PhotoCaptureDelegate?

    func start() async throws -> String {
        guard await isAuthorized() else { throw CaptureError.permissionDenied }
        let device = try configure()
        if !session.isRunning {
            session.startRunning()
        }
        return device.uniqueID
    }

    func stop() {
        if session.isRunning {
            session.stopRunning()
        }
    }

    func capturePhoto() async throws -> CapturedPhoto {
        guard session.isRunning, let rotationCoordinator, let connection = photoOutput.connection(with: .video) else {
            throw CaptureError.notRunning
        }
        let angle = rotationCoordinator.videoRotationAngleForHorizonLevelCapture
        if connection.isVideoRotationAngleSupported(angle) {
            connection.videoRotationAngle = angle
        }
        // The photo output always calls `didFinishCaptureFor`, so this await always returns.
        let data = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, any Error>) in
            let delegate = PhotoCaptureDelegate(continuation: continuation)
            inFlight = delegate
            photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: delegate)
        }
        inFlight = nil
        return CapturedPhoto(data: data, rotationAngle: angle)
    }

    private func isAuthorized() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: true
        case .notDetermined: await AVCaptureDevice.requestAccess(for: .video)
        default: false
        }
    }

    private func configure() throws -> AVCaptureDevice {
        if let device {
            return device
        }
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CaptureError.cameraUnavailable
        }
        guard let input = try? AVCaptureDeviceInput(device: camera) else {
            throw CaptureError.configurationFailed
        }
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .photo
        guard session.canAddInput(input), session.canAddOutput(photoOutput) else {
            throw CaptureError.configurationFailed
        }
        session.addInput(input)
        session.addOutput(photoOutput)
        rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: camera, previewLayer: nil)
        device = camera
        return camera
    }
}
