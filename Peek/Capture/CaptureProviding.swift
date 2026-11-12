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
    func stop() async
    func capturePhoto() async throws -> CapturedPhoto
}
