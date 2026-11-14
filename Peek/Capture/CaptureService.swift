import AVFoundation

/// Owns the one capture session. It starts with the rear camera (PRD FR-02).
/// The UX lookbook (page 07A) adds the front camera for a group selfie. The session has one input at a time.
actor CaptureService: CaptureProviding {
    nonisolated(unsafe) let session = AVCaptureSession()
    nonisolated let frameSource = FrameSource()
    private let photoOutput = AVCapturePhotoOutput()
    private let frameOutput = AVCaptureVideoDataOutput()
    private var device: AVCaptureDevice?
    private var input: AVCaptureDeviceInput?
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

    func selectCamera(_ facing: CameraFacing) throws -> String {
        guard let current = device, let oldInput = input else { throw CaptureError.notRunning }
        let position: AVCaptureDevice.Position = facing == .front ? .front : .back
        guard current.position != position else { return current.uniqueID }
        // On iPhone Duo the front wide-angle camera is the virtual front camera. It follows the display in use.
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            throw CaptureError.cameraUnavailable
        }
        guard let newInput = try? AVCaptureDeviceInput(device: camera) else {
            throw CaptureError.configurationFailed
        }
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.removeInput(oldInput)
        guard session.canAddInput(newInput) else {
            // The old camera comes back, so the booth continues.
            session.addInput(oldInput)
            throw CaptureError.configurationFailed
        }
        session.addInput(newInput)
        input = newInput
        rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: camera, previewLayer: nil)
        device = camera
        return camera.uniqueID
    }

    func stop() {
        if session.isRunning {
            session.stopRunning()
        }
    }

    func setFrameRotationAngle(_ angle: CGFloat) {
        guard let connection = frameOutput.connection(with: .video), connection.isVideoRotationAngleSupported(angle)
        else { return }
        connection.videoRotationAngle = angle
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
        // The frame feed is an enhancement for the outer display. The booth works without it.
        if session.canAddOutput(frameOutput) {
            frameOutput.alwaysDiscardsLateVideoFrames = true
            frameOutput.setSampleBufferDelegate(frameSource, queue: frameSource.queue)
            session.addOutput(frameOutput)
        }
        rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: camera, previewLayer: nil)
        device = camera
        self.input = input
        return camera
    }
}
