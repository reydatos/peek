import AVFoundation

/// The camera seam. Tests supply a fake.
nonisolated protocol CaptureProviding: Sendable {
    /// The session that preview layers attach to.
    var session: AVCaptureSession { get }
    /// Live frames for displays that cannot use a preview layer.
    var frameSource: FrameSource { get }
    /// Sets the rotation of the frames that `frameSource` sends.
    func setFrameRotationAngle(_ angle: CGFloat) async
    /// Asks for camera access if needed, then starts the session. Returns the camera's unique ID.
    func start() async throws -> String
    /// Changes the one camera input. Returns the unique ID of the new camera.
    func selectCamera(_ facing: CameraFacing) async throws -> String
    func stop() async
    /// The zoom factors that the camera in use gives with no upscale. The first one is 1.
    func zoomFactors() async -> [Double]
    /// Sets the zoom of the camera in use.
    func setZoom(_ factor: Double) async throws
    func capturePhoto() async throws -> CapturedPhoto
    /// Records a short silent clip of a pose to the file, and gives its last frame as JPEG bytes.
    func recordClip(to url: URL) async throws -> Data
}
