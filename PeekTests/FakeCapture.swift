import AVFoundation
import Foundation
@testable import Peek
import PeekCore

actor FakeCapture: CaptureProviding {
    /// A 1 x 1 PNG.
    static let photoData = Data(base64Encoded:
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==") ?? Data()

    nonisolated(unsafe) let session = AVCaptureSession()
    nonisolated let frameSource = FrameSource()
    private let startError: CaptureError?
    private let captureError: CaptureError?
    private(set) var captureCount = 0

    init(startError: CaptureError? = nil, captureError: CaptureError? = nil) {
        self.startError = startError
        self.captureError = captureError
    }

    func start() throws -> String {
        if let startError {
            throw startError
        }
        return "fake-camera"
    }

    func selectCamera(_ facing: CameraFacing) throws -> String {
        if let startError {
            throw startError
        }
        return facing == .front ? "fake-front-camera" : "fake-camera"
    }

    func stop() {}

    private(set) var zoom = 1.0
    var zoomError: CaptureError?

    func failZoom(_ fails: Bool) {
        zoomError = fails ? .configurationFailed : nil
    }

    func zoomFactors() -> [Double] {
        [1, 2]
    }

    func setZoom(_ factor: Double) throws {
        if let zoomError {
            throw zoomError
        }
        zoom = factor
    }

    func setFrameRotationAngle(_: CGFloat) {}

    private(set) var clipCount = 0
    var clipError: CaptureError?

    func failClips(_ fails: Bool) {
        clipError = fails ? .captureFailed : nil
    }

    /// The length that each recording asked for.
    private(set) var clipDurations: [Double] = []

    /// A real video that each recording copies. Nil writes a few bytes that are not video.
    private var clipSource: URL?

    func setClipSource(_ url: URL) {
        clipSource = url
    }

    func recordClip(to url: URL, duration: Double) throws -> Data {
        if let clipError {
            throw clipError
        }
        clipCount += 1
        clipDurations.append(duration)
        if let clipSource {
            try FileManager.default.copyItem(at: clipSource, to: url)
        } else {
            try Data("clip \(clipCount)".utf8).write(to: url)
        }
        return Self.photoData
    }

    private(set) var poseHandler: (@Sendable (PoseSignature) -> Void)?

    func setPoseHandler(_ handler: (@Sendable (PoseSignature) -> Void)?) {
        poseHandler = handler
    }

    func capturePhoto() throws -> CapturedPhoto {
        captureCount += 1
        if let captureError {
            throw captureError
        }
        return CapturedPhoto(data: Self.photoData, rotationAngle: 90)
    }
}
