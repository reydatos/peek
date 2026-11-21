import AVFoundation
import UIKit

/// Makes the duet video: for each pose, the clip of the pose above the clip of the people, with the score.
/// The video is upright, silent, and H.264, so each share target can play it.
///
/// The sizes are design values. Pose reference clips of a pack show the people who made that pack.
nonisolated enum DuetVideo {
    /// One pose of the video.
    struct Segment: Sendable {
        /// The clip of the pose, from the pack.
        let pose: URL
        /// The clip of the people, from the countdown.
        let attempt: URL
        /// The words below the two clips, for example "Pose 1 · 92% match".
        let label: String
    }

    /// The colors and the wordmark, made on the main actor.
    struct Style: @unchecked Sendable {
        let paper: CGColor
        let ink: CGColor
        let wordmark: CGImage?

        /// The cream paper of the strip.
        @MainActor static var paper: Style {
            let strip = StripRenderer.Style.paper(.cream)
            return Style(paper: strip.paper.cgColor, ink: strip.ink.cgColor, wordmark: strip.wordmark?.cgImage)
        }
    }

    enum Failure: Error {
        /// No pose has the two clips.
        case empty
        /// A clip has no picture track.
        case clip
        /// The system did not write the video.
        case export
        /// The video took longer than `timeout`. The system stopped, so the app stopped the video.
        case timeout
    }

    /// The longest time that one video may take. The owner chose this value (2026-11-20).
    /// In a test, the reader of the system once waited and did not continue; the timeout ends such a wait.
    static let timeout = Duration.seconds(30)

    static let size = CGSize(width: 1080, height: 1920)
    /// Each clip is 3:4.
    static let panel = CGSize(width: 648, height: 864)
    static let margin: CGFloat = 24
    static let footer: CGFloat = 120

    /// The frame of the pose clip, with the origin at the top left.
    static var poseFrame: CGRect {
        CGRect(x: (size.width - panel.width) / 2, y: margin, width: panel.width, height: panel.height)
    }

    /// The frame of the clip of the people.
    static var attemptFrame: CGRect {
        poseFrame.offsetBy(dx: 0, dy: panel.height + margin)
    }

    /// Writes the video to the file. Each pose has the length of the clip of its people; its pose clip gets
    /// that length too, so the two clips end in the pose at the same time.
    static func make(_ segments: [Segment], to url: URL, style: Style, timeout: Duration = DuetVideo.timeout) async throws {
        guard !segments.isEmpty else { throw Failure.empty }
        let composition = AVMutableComposition()
        guard
            let poseTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
            let attemptTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        else { throw Failure.export }

        var instructions: [AVMutableVideoCompositionInstruction] = []
        var ranges: [CMTimeRange] = []
        var cursor = CMTime.zero
        for segment in segments {
            let pose = try await source(segment.pose)
            let attempt = try await source(segment.attempt)
            let range = CMTimeRange(start: cursor, duration: attempt.range.duration)
            try attemptTrack.insertTimeRange(attempt.range, of: attempt.track, at: cursor)
            try poseTrack.insertTimeRange(pose.range, of: pose.track, at: cursor)
            poseTrack.scaleTimeRange(CMTimeRange(start: cursor, duration: pose.range.duration), toDuration: range.duration)

            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = range
            let poseLayer = AVMutableVideoCompositionLayerInstruction(assetTrack: poseTrack)
            poseLayer.setTransform(placement(of: pose, in: poseFrame), at: cursor)
            let attemptLayer = AVMutableVideoCompositionLayerInstruction(assetTrack: attemptTrack)
            attemptLayer.setTransform(placement(of: attempt, in: attemptFrame), at: cursor)
            instruction.layerInstructions = [poseLayer, attemptLayer]
            instructions.append(instruction)
            ranges.append(range)
            cursor = range.end
        }

        let video = AVMutableVideoComposition()
        video.renderSize = size
        video.frameDuration = CMTime(value: 1, timescale: 30)
        video.instructions = instructions
        let covers = zip(ranges, segments).compactMap { range, segment in
            cover(label: segment.label, style: style).map { (range: range, image: $0) }
        }
        guard covers.count == segments.count else { throw Failure.export }
        try await write(composition, video: video, covers: covers, to: url, timeout: timeout)
    }

    /// Reads each frame of the two clips together, draws the cover of its pose on it, and writes it.
    /// The system tool for a layer above a video stops the app in the simulator, so the app draws the frames.
    private static func write(
        _ composition: AVMutableComposition,
        video: AVMutableVideoComposition,
        covers: [(range: CMTimeRange, image: CGImage)],
        to url: URL,
        timeout: Duration
    ) async throws {
        try? FileManager.default.removeItem(at: url)
        guard let reader = try? AVAssetReader(asset: composition), let writer = try? AVAssetWriter(outputURL: url, fileType: .mp4) else {
            throw Failure.export
        }
        let output = AVAssetReaderVideoCompositionOutput(
            videoTracks: composition.tracks(withMediaType: .video),
            videoSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        )
        output.videoComposition = video
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height),
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: bitRate],
        ])
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)
        guard reader.canAdd(output), writer.canAdd(input) else { throw Failure.export }
        reader.add(output)
        writer.add(input)
        guard reader.startReading(), writer.startWriting() else { throw Failure.export }
        writer.startSession(atSourceTime: .zero)
        // The reader and the writer wait for the system, so they have their own queue and no shared worker thread.
        // Each call to the writer is on this queue.
        let queue = DispatchQueue(label: "com.a8media.peek.duet")
        nonisolated(unsafe) let job = (reader: reader, writer: writer, output: output, input: input, adaptor: adaptor)
        var timer: Task<Void, Never>?
        let outcome: Outcome = await withCheckedContinuation { continuation in
            let result = OneResult(continuation)
            job.input.requestMediaDataWhenReady(on: queue) {
                while result.isOpen, job.input.isReadyForMoreMediaData {
                    guard let sample = job.output.copyNextSampleBuffer() else {
                        // The reader also ends here after a timeout cancelled it. The timeout then has the result.
                        guard result.isOpen else { return }
                        job.input.markAsFinished()
                        guard job.reader.status == .completed else {
                            job.writer.cancelWriting()
                            result.give(.failed)
                            return
                        }
                        job.writer.finishWriting {
                            result.give(job.writer.status == .completed ? .written : .failed)
                        }
                        return
                    }
                    guard let frame = CMSampleBufferGetImageBuffer(sample) else { continue }
                    let time = CMSampleBufferGetPresentationTimeStamp(sample)
                    if let cover = covers.first(where: { $0.range.containsTime(time) }) ?? covers.last {
                        draw(cover.image, on: frame)
                    }
                    guard job.adaptor.append(frame, withPresentationTime: time) else {
                        job.reader.cancelReading()
                        job.writer.cancelWriting()
                        result.give(.failed)
                        return
                    }
                }
            }
            // A reader of the system can wait and not continue. The timeout then stops the video.
            timer = Task {
                try? await Task.sleep(for: timeout)
                guard !Task.isCancelled, result.give(.timedOut) else { return }
                // Cancelling the reader ends a call that waits for a frame. The writer is cancelled on its queue,
                // after the frame loop sees that the result is given.
                job.reader.cancelReading()
                queue.async { job.writer.cancelWriting() }
            }
        }
        timer?.cancel()
        switch outcome {
        case .written:
            return
        case .failed:
            try? FileManager.default.removeItem(at: url)
            throw Failure.export
        case .timedOut:
            // The caller does not wait for the queue: it can wait for the system and not continue.
            try? FileManager.default.removeItem(at: url)
            throw Failure.timeout
        }
    }

    private enum Outcome {
        case written, failed, timedOut
    }

    /// The result of one video. It goes to the caller one time: from the frame loop, the writer, or the timeout.
    private final class OneResult: @unchecked Sendable {
        private let lock = NSLock()
        private var continuation: CheckedContinuation<Outcome, Never>?

        init(_ continuation: CheckedContinuation<Outcome, Never>) {
            self.continuation = continuation
        }

        /// True until the result is given.
        var isOpen: Bool {
            lock.withLock { continuation != nil }
        }

        /// Gives the result to the caller. False when the caller already has a result.
        @discardableResult
        func give(_ outcome: Outcome) -> Bool {
            let waiting = lock.withLock {
                defer { continuation = nil }
                return continuation
            }
            waiting?.resume(returning: outcome)
            return waiting != nil
        }
    }

    /// The average bit rate of the video, in bits per second. This is a design value.
    static let bitRate = 6_000_000

    private static func draw(_ cover: CGImage, on frame: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(frame, [])
        defer { CVPixelBufferUnlockBaseAddress(frame, []) }
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(frame),
            width: CVPixelBufferGetWidth(frame),
            height: CVPixelBufferGetHeight(frame),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(frame),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return }
        context.draw(cover, in: CGRect(x: 0, y: 0, width: context.width, height: context.height))
    }

    /// The picture that goes above each frame of one pose: the paper with two openings for the clips,
    /// the wordmark, and the label of the pose.
    static func cover(label: String, style: Style) -> CGImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor(cgColor: style.paper).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            context.cgContext.clear(poseFrame)
            context.cgContext.clear(attemptFrame)
            let band = CGRect(x: margin * 2, y: size.height - footer - margin, width: size.width - margin * 4, height: footer)
            if let wordmark = style.wordmark, wordmark.height > 0 {
                let height = footer / 2
                let width = height * CGFloat(wordmark.width) / CGFloat(wordmark.height)
                UIImage(cgImage: wordmark).draw(in: CGRect(x: band.minX, y: band.midY - height / 2, width: width, height: height))
            }
            let words = NSAttributedString(string: label, attributes: [
                .font: UIFont.systemFont(ofSize: footer / 3, weight: .bold),
                .foregroundColor: UIColor(cgColor: style.ink),
            ])
            words.draw(at: CGPoint(x: band.maxX - words.size().width, y: band.midY - words.size().height / 2))
        }
        return image.cgImage
    }

    private struct Source {
        /// The track does not keep its asset, so the source does.
        let asset: AVURLAsset
        let track: AVAssetTrack
        let range: CMTimeRange
        let naturalSize: CGSize
        let transform: CGAffineTransform
    }

    private static func source(_ url: URL) async throws -> Source {
        let asset = AVURLAsset(url: url)
        guard let track = try? await asset.loadTracks(withMediaType: .video).first else { throw Failure.clip }
        let (fullRange, size, transform, segments) = try await track.load(.timeRange, .naturalSize, .preferredTransform, .segments)
        // A clip can start with no picture: a recorder that dropped its first frames made it. The video uses the
        // clip from its first picture, so its panel is never empty.
        let firstPicture = segments.first { !$0.isEmpty }?.timeMapping.target.start ?? fullRange.start
        let range = CMTimeRange(start: CMTimeMaximum(fullRange.start, firstPicture), end: fullRange.end)
        guard range.duration.seconds > 0, size.width > 0, size.height > 0 else { throw Failure.clip }
        return Source(asset: asset, track: track, range: range, naturalSize: size, transform: transform)
    }

    /// The transform that puts the upright picture of a clip in a frame of the video. The clip covers the frame.
    static func placement(naturalSize: CGSize, transform: CGAffineTransform, in frame: CGRect) -> CGAffineTransform {
        // The stored picture with its own turn or mirror, moved so that its corner is at the origin.
        let shown = CGRect(origin: .zero, size: naturalSize).applying(transform)
        let scale = max(frame.width / shown.width, frame.height / shown.height)
        return transform
            .concatenating(CGAffineTransform(translationX: -shown.minX, y: -shown.minY))
            .concatenating(CGAffineTransform(scaleX: scale, y: scale))
            .concatenating(CGAffineTransform(
                translationX: frame.midX - shown.width * scale / 2,
                y: frame.midY - shown.height * scale / 2
            ))
    }

    private static func placement(of source: Source, in frame: CGRect) -> CGAffineTransform {
        placement(naturalSize: source.naturalSize, transform: source.transform, in: frame)
    }
}
