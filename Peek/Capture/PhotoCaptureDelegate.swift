import AVFoundation

/// Bridges one photo capture to a continuation. It resumes one time, in `didFinishCaptureFor`.
final nonisolated class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    private let continuation: CheckedContinuation<Data, any Error>
    private var data: Data?

    init(continuation: CheckedContinuation<Data, any Error>) {
        self.continuation = continuation
    }

    func photoOutput(_: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        if error == nil {
            data = photo.fileDataRepresentation()
        }
    }

    func photoOutput(
        _: AVCapturePhotoOutput,
        didFinishCaptureFor _: AVCaptureResolvedPhotoSettings,
        error: (any Error)?
    ) {
        if let data, error == nil {
            continuation.resume(returning: data)
        } else {
            continuation.resume(throwing: CaptureError.captureFailed)
        }
    }
}
