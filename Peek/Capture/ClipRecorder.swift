import AVFoundation
import CoreImage
import UIKit

/// Records a short silent clip of a pose from the live frames, and gives the last frame as the still picture.
///
/// The clip is upright and 3:4, as each pose picture is. The frames come as the camera gives them, so the
/// recorder gets the rotation that makes them upright: it writes that rotation in the clip, and it turns the
/// still picture. A frame that is not 3:4 after the rotation loses its sides or its top and bottom.
///
/// The clip has no sound, so the app needs no microphone access.
final nonisolated class ClipRecorder: @unchecked Sendable {
    /// The length of a clip, in seconds (owner decision, 2026-11-15).
    static let duration = 5.0
    /// The size of a clip: 720 x 960, upright. This is a design value.
    static let shortSide = 720
    static let longSide = 960
    /// The average bit rate of a clip, in bits per second. This is a design value: a clip is then about 1 MB.
    static let bitRate = 1_500_000

    enum Failure: Error {
        /// The writer did not start, or it stopped with a fault.
        case writer
        /// The last frame did not become a picture.
        case still
        /// The recording stopped before the end: the camera gave no frames, or the caller stopped it.
        case stopped
    }

    private let lock = NSLock()
    private let writer: AVAssetWriter?
    private let input: AVAssetWriterInput
    private let duration: Double
    private let quarterTurns: Int
    private var start: CMTime?
    private var lastFrame: CVPixelBuffer?
    private var isDone = false
    private var completion: (@Sendable (Result<Data, any Error>) -> Void)?

    /// - Parameters:
    ///   - rotationAngle: the clockwise angle, in degrees, that makes a frame upright: 0, 90, 180, or 270.
    ///   - completion: runs one time, with the JPEG bytes of the last frame, or with the fault.
    init(
        url: URL,
        rotationAngle: CGFloat,
        duration: Double = ClipRecorder.duration,
        codec: AVVideoCodecType = .hevc,
        completion: @escaping @Sendable (Result<Data, any Error>) -> Void
    ) {
        self.duration = duration
        self.completion = completion
        quarterTurns = ((Int((rotationAngle / 90).rounded()) % 4) + 4) % 4
        // The writer stores the frame as the camera gives it. With a quarter turn, the stored frame is wide,
        // and the rotation in the clip makes it upright.
        let isSideways = quarterTurns % 2 == 1
        input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: codec,
            AVVideoWidthKey: isSideways ? Self.longSide : Self.shortSide,
            AVVideoHeightKey: isSideways ? Self.shortSide : Self.longSide,
            AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill,
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: Self.bitRate],
        ])
        input.expectsMediaDataInRealTime = true
        input.transform = CGAffineTransform(rotationAngle: CGFloat(quarterTurns) * .pi / 2)
        try? FileManager.default.removeItem(at: url)
        let writer = try? AVAssetWriter(outputURL: url, fileType: .mov)
        if let writer, writer.canAdd(input) {
            writer.add(input)
            self.writer = writer
        } else {
            self.writer = nil
        }
    }

    /// Takes one live frame. Call this on one queue, in the order of the frames.
    func append(_ sampleBuffer: CMSampleBuffer) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        lock.lock()
        defer { lock.unlock() }
        guard !isDone else { return }
        guard let writer else {
            finish(.failure(Failure.writer))
            return
        }
        if start == nil {
            guard writer.startWriting() else {
                finish(.failure(Failure.writer))
                return
            }
            writer.startSession(atSourceTime: time)
            start = time
        }
        guard let start else { return }
        if CMTimeGetSeconds(CMTimeSubtract(time, start)) >= duration {
            isDone = true
            input.markAsFinished()
            // The clip ends at this frame, so its length is the full length and not the time of the last stored frame.
            writer.endSession(atSourceTime: time)
            // The lock is not held in the completion of the writer.
            nonisolated(unsafe) let last = lastFrame ?? frame
            writer.finishWriting { [self] in
                let result: Result<Data, any Error> = writer.status == .completed
                    ? Self.still(of: last, quarterTurns: quarterTurns).map { .success($0) } ?? .failure(Failure.still)
                    : .failure(Failure.writer)
                deliver(result)
            }
            return
        }
        if input.isReadyForMoreMediaData {
            if input.append(sampleBuffer) {
                lastFrame = frame
            } else {
                finish(.failure(Failure.writer))
            }
        }
    }

    /// Stops a recording that did not come to its end. The clip file is removed.
    func stop() {
        lock.lock()
        defer { lock.unlock() }
        guard !isDone else { return }
        finish(.failure(Failure.stopped))
    }

    /// Ends the recording with a fault. The caller holds the lock.
    private func finish(_ result: Result<Data, any Error>) {
        isDone = true
        if let writer, writer.status == .writing {
            writer.cancelWriting()
        }
        let completion = completion
        self.completion = nil
        completion?(result)
    }

    private func deliver(_ result: Result<Data, any Error>) {
        let completion = lock.withLock {
            defer { self.completion = nil }
            return self.completion
        }
        completion?(result)
    }

    /// The upright 3:4 picture of a frame, as JPEG bytes.
    static func still(of frame: CVPixelBuffer, quarterTurns: Int) -> Data? {
        let orientations: [CGImagePropertyOrientation] = [.up, .right, .down, .left]
        let upright = CIImage(cvPixelBuffer: frame).oriented(orientations[((quarterTurns % 4) + 4) % 4])
        let cropped = upright.cropped(to: uprightCrop(of: upright.extent))
        let context = CIContext()
        guard let image = context.createCGImage(cropped, from: cropped.extent) else { return nil }
        return UIImage(cgImage: image).jpegData(compressionQuality: 0.8)
    }

    /// The largest 3:4 part of a picture, in its center.
    static func uprightCrop(of extent: CGRect) -> CGRect {
        let aspect = CGFloat(shortSide) / CGFloat(longSide)
        let width = min(extent.width, extent.height * aspect)
        let height = width / aspect
        return CGRect(x: extent.midX - width / 2, y: extent.midY - height / 2, width: width, height: height)
    }
}
