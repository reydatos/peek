import AVFoundation
import CoreImage
import UIKit

/// Records a short silent clip of a pose from the live frames, and gives the last frame as the still picture.
///
/// The frames come as the camera gives them, so the recorder gets the rotation that makes them level: it writes
/// that rotation in the clip, and it turns the still picture. A clip from an upright camera picture is upright
/// and 3:4, as each pose picture is. A clip from a wide camera picture keeps its full width, 4:3. The still
/// picture is always the upright 3:4 middle part.
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
    /// The app makes the input at the first frame, because the size of the clip comes from the shape of the frame.
    private var input: AVAssetWriterInput?
    private let codec: AVVideoCodecType
    private let duration: Double
    private let quarterTurns: Int
    private let isMirrored: Bool
    private var start: CMTime?
    private var lastFrame: CVPixelBuffer?
    private var isDone = false
    private var completion: (@Sendable (Result<Data, any Error>) -> Void)?
    /// True when the input takes a frame now. Tests replace it to act as a busy encoder.
    private let isReady: @Sendable (AVAssetWriterInput) -> Bool

    /// - Parameters:
    ///   - rotationAngle: the clockwise angle, in degrees, that makes a frame upright: 0, 90, 180, or 270.
    ///   - isMirrored: true for the front camera. The clip and the still picture are then a mirror picture,
    ///     the same as the live view that the person saw.
    ///   - completion: runs one time, with the JPEG bytes of the last frame, or with the fault.
    init(
        url: URL,
        rotationAngle: CGFloat,
        isMirrored: Bool = false,
        duration: Double = ClipRecorder.duration,
        codec: AVVideoCodecType = .hevc,
        isReady: @escaping @Sendable (AVAssetWriterInput) -> Bool = { $0.isReadyForMoreMediaData },
        completion: @escaping @Sendable (Result<Data, any Error>) -> Void
    ) {
        self.isReady = isReady
        self.duration = duration
        self.completion = completion
        self.isMirrored = isMirrored
        self.codec = codec
        quarterTurns = ((Int((rotationAngle / 90).rounded()) % 4) + 4) % 4
        try? FileManager.default.removeItem(at: url)
        writer = try? AVAssetWriter(outputURL: url, fileType: .mov)
    }

    /// The size that the writer stores for a frame of this size.
    ///
    /// The writer stores the frame as the camera gives it, and the rotation in the clip makes it level.
    /// A frame that is upright when level gives the upright 3:4 clip. A frame that is wide when level keeps its
    /// full width (owner decision, 2026-11-17): the outer display shows such a clip from edge to edge, and a
    /// 3:4 view shows its middle part.
    static func storedSize(frameWidth: Int, frameHeight: Int, quarterTurns: Int) -> (width: Int, height: Int) {
        let isSideways = quarterTurns % 2 == 1
        let isWideWhenLevel = isSideways ? frameHeight > frameWidth : frameWidth > frameHeight
        // The stored frame is wide when exactly one of the two is true: the level picture is wide, or it has a quarter turn.
        return isWideWhenLevel != isSideways ? (longSide, shortSide) : (shortSide, longSide)
    }

    /// Makes the input for the first frame. The caller holds the lock.
    private func makeInput(for frame: CVPixelBuffer, in writer: AVAssetWriter) -> AVAssetWriterInput? {
        let size = Self.storedSize(
            frameWidth: CVPixelBufferGetWidth(frame),
            frameHeight: CVPixelBufferGetHeight(frame),
            quarterTurns: quarterTurns
        )
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: codec,
            AVVideoWidthKey: size.width,
            AVVideoHeightKey: size.height,
            AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill,
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: Self.bitRate],
        ])
        input.expectsMediaDataInRealTime = true
        input.transform = Self.transform(quarterTurns: quarterTurns, isMirrored: isMirrored)
        guard writer.canAdd(input) else { return nil }
        writer.add(input)
        return input
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
        if input == nil {
            input = makeInput(for: frame, in: writer)
            guard input != nil, writer.startWriting() else {
                finish(.failure(Failure.writer))
                return
            }
        }
        guard let input else { return }
        // The clip starts at the first frame that the encoder takes, so it has a picture from its first moment.
        // A frame before that is dropped, as each live frame is while the encoder is busy.
        guard let start else {
            guard isReady(input) else { return }
            writer.startSession(atSourceTime: time)
            start = time
            if input.append(sampleBuffer) {
                lastFrame = frame
            } else {
                finish(.failure(Failure.writer))
            }
            return
        }
        if CMTimeGetSeconds(CMTimeSubtract(time, start)) >= duration {
            isDone = true
            input.markAsFinished()
            // The clip ends at this frame, so its length is the full length and not the time of the last stored frame.
            writer.endSession(atSourceTime: time)
            // The lock is not held in the completion of the writer.
            nonisolated(unsafe) let last = lastFrame ?? frame
            writer.finishWriting { [self] in
                let result: Result<Data, any Error> = writer.status == .completed
                    ? Self.still(of: last, quarterTurns: quarterTurns, isMirrored: isMirrored).map { .success($0) } ?? .failure(Failure.still)
                    : .failure(Failure.writer)
                deliver(result)
            }
            return
        }
        if isReady(input) {
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

    /// The rotation that the clip stores. For a mirror picture, the upright frame is then flipped left to right.
    static func transform(quarterTurns: Int, isMirrored: Bool) -> CGAffineTransform {
        let turn = CGAffineTransform(rotationAngle: CGFloat(quarterTurns) * .pi / 2)
        return isMirrored ? turn.concatenating(CGAffineTransform(scaleX: -1, y: 1)) : turn
    }

    /// The upright 3:4 picture of a frame, as JPEG bytes.
    static func still(of frame: CVPixelBuffer, quarterTurns: Int, isMirrored: Bool = false) -> Data? {
        let orientations: [CGImagePropertyOrientation] = [.up, .right, .down, .left]
        var upright = CIImage(cvPixelBuffer: frame).oriented(orientations[((quarterTurns % 4) + 4) % 4])
        if isMirrored {
            upright = upright.oriented(.upMirrored)
        }
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
