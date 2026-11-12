import AVFoundation
import Foundation
@testable import Peek

actor FakeCapture: CaptureProviding {
    /// A 1 x 1 PNG.
    static let photoData = Data(base64Encoded:
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==") ?? Data()

    nonisolated(unsafe) let session = AVCaptureSession()
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

    func stop() {}

    func capturePhoto() throws -> CapturedPhoto {
        captureCount += 1
        if let captureError {
            throw captureError
        }
        return CapturedPhoto(data: Self.photoData, rotationAngle: 90)
    }
}
