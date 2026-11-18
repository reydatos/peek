import AVFoundation
import PeekCore

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
    private var poseHandler: (@Sendable (PoseSignature) -> Void)?
    /// True while one frame is in examination. A frame that comes then is not examined.
    private var isExaminingPose = false

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

    /// The factors come from the camera: 1, and each factor at which the sensor gives its native resolution.
    /// A camera with no such factor has one value, and the booth then shows no zoom control.
    func zoomFactors() -> [Double] {
        guard let device else { return [] }
        let range = device.minAvailableVideoZoomFactor ... device.maxAvailableVideoZoomFactor
        let native = device.activeFormat.secondaryNativeResolutionZoomFactors.filter(range.contains)
        return [1] + native.map(Double.init).filter { $0 != 1 }.sorted()
    }

    func setZoom(_ factor: Double) throws {
        guard let device else { throw CaptureError.notRunning }
        let range = device.minAvailableVideoZoomFactor ... device.maxAvailableVideoZoomFactor
        guard range.contains(CGFloat(factor)) else { throw CaptureError.configurationFailed }
        do {
            try device.lockForConfiguration()
        } catch {
            throw CaptureError.configurationFailed
        }
        device.videoZoomFactor = CGFloat(factor)
        device.unlockForConfiguration()
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

    /// The time that the camera gets to give the first frames, in seconds, after the length of the clip.
    /// A recording that is not complete after that time stops with a fault. This is a design value.
    private static let clipAllowance = 3.0

    func recordClip(to url: URL, duration: Double) async throws -> Data {
        guard session.isRunning, let rotationCoordinator else { throw CaptureError.notRunning }
        // The frames have the rotation of the frame connection. The clip needs the rotation of a level photo.
        let level = rotationCoordinator.videoRotationAngleForHorizonLevelCapture
        let current = frameOutput.connection(with: .video)?.videoRotationAngle ?? 0
        let source = frameSource
        // The live view of the front camera is a mirror. The clip of a selfie pose is the same mirror picture.
        let isMirrored = device?.position == .front
        return try await withThrowingTaskGroup(of: Data.self) { group in
            group.addTask { try await source.record(to: url, rotationAngle: level - current, isMirrored: isMirrored, duration: duration) }
            group.addTask {
                try await Task.sleep(for: .seconds(duration + Self.clipAllowance))
                throw CaptureError.captureFailed
            }
            defer { group.cancelAll() }
            guard let still = try await group.next() else { throw CaptureError.captureFailed }
            return still
        }
    }

    func setPoseHandler(_ handler: (@Sendable (PoseSignature) -> Void)?) {
        poseHandler = handler
        guard handler != nil else {
            frameSource.setPoseFrameHandler(nil)
            return
        }
        frameSource.setPoseFrameHandler { [weak self] frame in
            // The frame is read only, and one task has it.
            let frame = LiveFrame(buffer: frame)
            Task { await self?.examinePose(in: frame.buffer) }
        }
    }

    private func examinePose(in frame: CMSampleBuffer) async {
        guard !isExaminingPose, poseHandler != nil, let rotationCoordinator else { return }
        isExaminingPose = true
        defer { isExaminingPose = false }
        // The same rotation as a clip: the frame has the rotation of the frame connection.
        let level = rotationCoordinator.videoRotationAngleForHorizonLevelCapture
        let current = frameOutput.connection(with: .video)?.videoRotationAngle ?? 0
        let orientation = PoseAnalyzer.orientation(rotationAngle: level - current)
        if let signature = await PoseAnalyzer.signature(in: frame, orientation: orientation) {
            poseHandler?(signature)
        }
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

/// A live frame on its way to the pose examination.
private nonisolated struct LiveFrame: @unchecked Sendable {
    let buffer: CMSampleBuffer
}
