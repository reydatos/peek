import AVFoundation
import UIKit

/// Makes the duet video: a split screen, edge to edge, with the clip of the pose above the clip of the people.
///
/// The video tells a short story: an intro card with the pack name, then for each pose a title card, the two clips,
/// a shutter flash, and the photo that the booth took, frozen while the match score counts up. The finished strip
/// is the last shot. The video is upright, silent, and H.264, so each share target can play it.
///
/// The sizes and the times are design values that the owner confirmed (2026-11-21). Pose reference clips of a
/// pack show the people who made that pack.
nonisolated enum DuetVideo {
    /// One pose of the video.
    struct Segment: @unchecked Sendable {
        /// The clip of the pose, from the pack.
        let pose: URL
        /// The clip of the people, from the countdown.
        let attempt: URL
        /// The caption and the title card, for example "POSE 2".
        let title: String
        /// The photo that the booth took, frozen after the flash. Nil freezes the last frame of the people.
        let photo: CGImage?
        /// The match score from 0 to 100. Nil shows no score.
        let percent: Int?

        init(pose: URL, attempt: URL, title: String, photo: CGImage? = nil, percent: Int? = nil) {
            self.pose = pose
            self.attempt = attempt
            self.title = title
            self.photo = photo
            self.percent = percent
        }
    }

    /// The cards at the start and at the end.
    struct Story: @unchecked Sendable {
        /// The big words of the intro card: the name of the pack.
        let title: String
        /// The words in the pill below the title, for example "DUET".
        let subtitle: String
        /// The finished strip, the last shot. Nil gives no outro.
        let strip: CGImage?
    }

    /// The fixed colors and the wordmark. The video has its own colors, as the exported strip has.
    struct Style: @unchecked Sendable {
        /// The color of the score pill and the subtitle pill.
        let accent: CGColor
        /// The wordmark. The video draws it white.
        let wordmark: CGImage?

        /// The PEEK red and wordmark, made on the main actor.
        @MainActor static var standard: Style {
            Style(accent: UIColor(PeekTheme.red).cgColor, wordmark: StripRenderer.Style.paper(.cream).wordmark?.cgImage)
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

    // MARK: Design values (owner, 2026-11-21)

    static let size = CGSize(width: 1080, height: 1920)
    static let framesPerSecond = 30
    /// The space between the edge of the video and a caption, the score, or the wordmark.
    static let inset: CGFloat = 48
    /// The white line between the two halves.
    static let divider: CGFloat = 8
    static let captionSize: CGFloat = 92
    static let badgeSize: CGFloat = 64
    static let wordmarkHeight: CGFloat = 56

    enum Timing {
        static let intro = 1.0
        static let title = 0.6
        static let flash = 0.15
        static let freeze = 0.8
        static let countUp = 0.6
        static let outro = 1.5
    }

    /// The clip of the pose: the top half, edge to edge.
    static var poseFrame: CGRect {
        CGRect(x: 0, y: 0, width: size.width, height: size.height / 2)
    }

    /// The clip of the people: the bottom half.
    static var attemptFrame: CGRect {
        poseFrame.offsetBy(dx: 0, dy: size.height / 2)
    }

    /// The score that the pill shows a time after the freeze started: it counts up for `Timing.countUp`.
    static func countUp(percent: Int, at seconds: Double) -> Int {
        guard seconds > 0 else { return 0 }
        return Int((Double(percent) * min(1, seconds / Timing.countUp)).rounded())
    }

    /// The size of the pill a time after the freeze started: 1 while it counts, then a pop that ends at 1.
    static func badgeScale(at seconds: Double) -> CGFloat {
        let pop = Timing.freeze - Timing.countUp
        guard seconds > Timing.countUp, pop > 0 else { return 1 }
        let progress = min(1, (seconds - Timing.countUp) / pop)
        // Up to 1.2 at the middle of the pop, then back to 1.
        return 1 + 0.2 * CGFloat(sin(progress * .pi))
    }

    // MARK: Making the video

    /// Writes the video to the file. Each pose has the length of the clip of its people; its pose clip gets that
    /// length too, so the two clips end in the pose at the same time.
    ///
    /// - Parameter progress: gets a value from 0 to 1 while the video is written, on a queue of the video.
    static func make(
        _ segments: [Segment],
        story: Story? = nil,
        to url: URL,
        style: Style,
        timeout: Duration = DuetVideo.timeout,
        progress: (@Sendable (Double) -> Void)? = nil
    ) async throws {
        guard !segments.isEmpty else { throw Failure.empty }
        var clips: [Clip] = []
        for segment in segments {
            try await clips.append(clip(for: segment))
        }
        let art = Art(style: style)
        var scenes: [Scene] = []
        if let story {
            scenes.append(.still(art.introCard(story), frames: frames(Timing.intro)))
        }
        for (segment, clip) in zip(segments, clips) {
            scenes.append(.still(art.titleCard(segment.title), frames: frames(Timing.title)))
            scenes.append(.clip(clip, caption: art.caption(segment.title)))
            scenes.append(.freeze(clip, segment: segment))
        }
        if let strip = story?.strip {
            scenes.append(.still(art.outroCard(strip), frames: frames(Timing.outro)))
        }
        try await write(scenes, art: art, to: url, timeout: timeout, progress: progress)
    }

    private static func frames(_ seconds: Double) -> Int {
        Int((seconds * Double(framesPerSecond)).rounded())
    }

    /// One part of the video.
    private enum Scene {
        /// One picture for a number of frames: a card.
        case still(CGImage?, frames: Int)
        /// The two clips of a pose, with the caption.
        case clip(Clip, caption: CGImage?)
        /// The flash and the frozen photo, with the score.
        case freeze(Clip, segment: Segment)

        var frameCount: Int {
            switch self {
            case let .still(_, frames): frames
            case let .clip(clip, _): DuetVideo.frames(clip.duration.seconds)
            case .freeze: DuetVideo.frames(Timing.flash + Timing.freeze)
            }
        }
    }

    /// The two clips of one pose as one composition, and what the freeze needs from them.
    private final class Clip: @unchecked Sendable {
        let composition: AVMutableComposition
        let video: AVMutableVideoComposition
        let duration: CMTime
        /// The last picture of the clip part, set while it is written. The freeze shows it.
        var lastFrame: CGImage?

        init(composition: AVMutableComposition, video: AVMutableVideoComposition, duration: CMTime) {
            self.composition = composition
            self.video = video
            self.duration = duration
        }
    }

    private static func clip(for segment: Segment) async throws -> Clip {
        let pose = try await source(segment.pose)
        let attempt = try await source(segment.attempt)
        let composition = AVMutableComposition()
        guard
            let poseTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
            let attemptTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        else { throw Failure.export }
        let range = CMTimeRange(start: .zero, duration: attempt.range.duration)
        try attemptTrack.insertTimeRange(attempt.range, of: attempt.track, at: .zero)
        try poseTrack.insertTimeRange(pose.range, of: pose.track, at: .zero)
        poseTrack.scaleTimeRange(CMTimeRange(start: .zero, duration: pose.range.duration), toDuration: range.duration)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = range
        // The first layer is on top. The clip of the people covers the bottom half, so the part of an upright pose
        // clip that is below the top half is under it. Each clip that is wider than the video ends at its edges.
        instruction.layerInstructions = [
            layer(of: attemptTrack, source: attempt, in: attemptFrame),
            layer(of: poseTrack, source: pose, in: poseFrame),
        ]
        let video = AVMutableVideoComposition()
        video.renderSize = size
        video.frameDuration = CMTime(value: 1, timescale: CMTimeScale(framesPerSecond))
        video.instructions = [instruction]
        return Clip(composition: composition, video: video, duration: range.duration)
    }

    /// The layer of one clip: it covers its half.
    private static func layer(
        of track: AVMutableCompositionTrack,
        source: Source,
        in frame: CGRect
    ) -> AVMutableVideoCompositionLayerInstruction {
        let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        layer.setTransform(placement(naturalSize: source.naturalSize, transform: source.transform, in: frame), at: .zero)
        return layer
    }

    // MARK: Writing

    private static func write(
        _ scenes: [Scene],
        art: Art,
        to url: URL,
        timeout: Duration,
        progress: (@Sendable (Double) -> Void)?
    ) async throws {
        // The writer has a file of its own, which goes to `url` when it is complete. A writer that a timeout stopped
        // cancels later, and a cancel removes the file of the writer: so it removes no video that came after it.
        let draft = url.deletingLastPathComponent().appending(path: ".duet-\(UUID().uuidString).mp4")
        guard let writer = try? AVAssetWriter(outputURL: draft, fileType: .mp4) else { throw Failure.export }
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height),
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: bitRate],
        ])
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: Int(size.width),
            kCVPixelBufferHeightKey as String: Int(size.height),
        ])
        guard writer.canAdd(input) else { throw Failure.export }
        writer.add(input)
        guard writer.startWriting() else { throw Failure.export }
        writer.startSession(atSourceTime: .zero)

        // The reader and the writer wait for the system, so they have their own queue and no shared worker thread.
        // Each call to the writer is on this queue.
        let queue = DispatchQueue(label: "com.a8media.peek.duet")
        let frames = Frames(scenes: scenes, art: art)
        nonisolated(unsafe) let job = (writer: writer, input: input, adaptor: adaptor)
        var timer: Task<Void, Never>?
        let outcome: Outcome = await withCheckedContinuation { continuation in
            let result = OneResult(continuation)
            job.input.requestMediaDataWhenReady(on: queue) {
                while result.isOpen, job.input.isReadyForMoreMediaData {
                    let next: (CVPixelBuffer, CMTime)?
                    do {
                        next = try frames.next(pool: job.adaptor.pixelBufferPool)
                    } catch {
                        frames.cancel()
                        job.writer.cancelWriting()
                        result.give(.failed)
                        return
                    }
                    guard let (frame, time) = next else {
                        job.input.markAsFinished()
                        job.writer.finishWriting {
                            result.give(job.writer.status == .completed ? .written : .failed)
                        }
                        return
                    }
                    guard job.adaptor.append(frame, withPresentationTime: time) else {
                        frames.cancel()
                        job.writer.cancelWriting()
                        result.give(.failed)
                        return
                    }
                    progress?(frames.progress)
                }
            }
            // A reader of the system can wait and not continue. The timeout then stops the video.
            timer = Task {
                try? await Task.sleep(for: timeout)
                guard !Task.isCancelled, result.give(.timedOut) else { return }
                // Cancelling the reader ends a call that waits for a frame. The writer is cancelled on its queue,
                // after the frame loop sees that the result is given.
                frames.cancel()
                queue.async { job.writer.cancelWriting() }
            }
        }
        timer?.cancel()
        switch outcome {
        case .written:
            do {
                try? FileManager.default.removeItem(at: url)
                try FileManager.default.moveItem(at: draft, to: url)
            } catch {
                try? FileManager.default.removeItem(at: draft)
                throw Failure.export
            }
        case .failed:
            try? FileManager.default.removeItem(at: draft)
            throw Failure.export
        case .timedOut:
            // The caller does not wait for the queue: it can wait for the system and not continue.
            try? FileManager.default.removeItem(at: draft)
            throw Failure.timeout
        }
    }

    /// The average bit rate of the video, in bits per second. This is a design value.
    static let bitRate = 6_000_000

    /// Gives the frames of the scenes one after the other, at `framesPerSecond`. It runs on the queue of the video.
    private final class Frames: @unchecked Sendable {
        private let scenes: [Scene]
        private let art: Art
        private let total: Int
        private var sceneIndex = 0
        private var frameInScene = 0
        private var written = 0
        private var reader: (reader: AVAssetReader, output: AVAssetReaderVideoCompositionOutput)?
        private let lock = NSLock()

        init(scenes: [Scene], art: Art) {
            self.scenes = scenes
            self.art = art
            total = max(1, scenes.reduce(0) { $0 + $1.frameCount })
        }

        var progress: Double {
            Double(written) / Double(total)
        }

        /// Stops a reader that waits for a frame. It can come from a different thread.
        func cancel() {
            lock.withLock { reader?.reader }?.cancelReading()
        }

        /// The next frame and its time, or nil after the last frame.
        func next(pool: CVPixelBufferPool?) throws -> (CVPixelBuffer, CMTime)? {
            while sceneIndex < scenes.count {
                if let frame = try frame(of: scenes[sceneIndex], pool: pool) {
                    let time = CMTime(value: CMTimeValue(written), timescale: CMTimeScale(DuetVideo.framesPerSecond))
                    written += 1
                    frameInScene += 1
                    return (frame, time)
                }
                sceneIndex += 1
                frameInScene = 0
            }
            return nil
        }

        /// The next frame of a scene, or nil at its end.
        private func frame(of scene: Scene, pool: CVPixelBufferPool?) throws -> CVPixelBuffer? {
            switch scene {
            case let .still(image, frames):
                guard frameInScene < frames else { return nil }
                return try drawn(pool: pool) { context in
                    if let image {
                        Canvas.draw(image, in: CGRect(origin: .zero, size: DuetVideo.size), on: context)
                    }
                }
            case let .clip(clip, caption):
                return try clipFrame(clip, caption: caption)
            case let .freeze(clip, segment):
                let count = DuetVideo.frames(Timing.flash + Timing.freeze)
                guard frameInScene < count else { return nil }
                let seconds = Double(frameInScene) / Double(DuetVideo.framesPerSecond)
                return try drawn(pool: pool) { context in
                    art.drawFreeze(clip: clip, segment: segment, at: seconds, on: context)
                }
            }
        }

        private func clipFrame(_ clip: Clip, caption: CGImage?) throws -> CVPixelBuffer? {
            if frameInScene == 0 {
                guard let reader = try? AVAssetReader(asset: clip.composition) else { throw Failure.export }
                let output = AVAssetReaderVideoCompositionOutput(
                    videoTracks: clip.composition.tracks(withMediaType: .video),
                    videoSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                )
                output.videoComposition = clip.video
                guard reader.canAdd(output) else { throw Failure.export }
                reader.add(output)
                guard reader.startReading() else { throw Failure.export }
                lock.withLock { self.reader = (reader, output) }
            }
            guard let current = lock.withLock({ reader }) else { return nil }
            guard let sample = current.output.copyNextSampleBuffer(), let frame = CMSampleBufferGetImageBuffer(sample) else {
                // The end of the clip, or a cancel.
                let status = current.reader.status
                lock.withLock { reader = nil }
                guard status == .completed else { throw Failure.export }
                // The freeze shows the last picture of the clips, with its caption.
                clip.lastFrame = lastClipFrame.flatMap(Canvas.image)
                lastClipFrame = nil
                return nil
            }
            Canvas.with(frame) { context in
                art.drawClipOverlay(caption: caption, on: context)
            }
            lastClipFrame = frame
            return frame
        }

        /// The last frame of the clip part that is written. Only the last one becomes a picture, at the end of the clip.
        private var lastClipFrame: CVPixelBuffer?

        private func drawn(pool: CVPixelBufferPool?, _ draw: (CGContext) -> Void) throws -> CVPixelBuffer {
            var buffer: CVPixelBuffer?
            if let pool {
                CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)
            }
            if buffer == nil {
                let attributes = [kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary] as CFDictionary
                CVPixelBufferCreate(nil, Int(DuetVideo.size.width), Int(DuetVideo.size.height), kCVPixelFormatType_32BGRA, attributes, &buffer)
            }
            guard let buffer else { throw Failure.export }
            Canvas.with(buffer) { context in
                context.setFillColor(UIColor.black.cgColor)
                context.fill(CGRect(origin: .zero, size: DuetVideo.size))
                draw(context)
            }
            return buffer
        }
    }

    // MARK: Pictures

    /// The pictures of the video, made before the frames: the cards, the captions, the score pills, the wordmark.
    private final class Art: @unchecked Sendable {
        let style: Style
        private let wordmark: CGImage?
        private var pills: [String: CGImage] = [:]

        init(style: Style) {
            self.style = style
            wordmark = style.wordmark.flatMap(Canvas.white)
        }

        func introCard(_ story: Story) -> CGImage? {
            Canvas.picture(size: DuetVideo.size) { context in
                let title = Canvas.text(story.title, size: DuetVideo.captionSize, weight: .heavy)
                let titleSize = title.boundingRect(
                    with: CGSize(width: DuetVideo.size.width - DuetVideo.inset * 2, height: .greatestFiniteMagnitude),
                    options: .usesLineFragmentOrigin, context: nil
                ).size
                let pill = self.pill(story.subtitle)
                let pillHeight = pill.map { CGFloat($0.height) } ?? 0
                let top = (DuetVideo.size.height - titleSize.height - DuetVideo.inset - pillHeight) / 2
                title.draw(with: CGRect(
                    x: (DuetVideo.size.width - titleSize.width) / 2, y: top, width: titleSize.width, height: titleSize.height
                ), options: .usesLineFragmentOrigin, context: nil)
                if let pill {
                    let rect = CGRect(
                        x: (DuetVideo.size.width - CGFloat(pill.width)) / 2, y: top + titleSize.height + DuetVideo.inset,
                        width: CGFloat(pill.width), height: CGFloat(pill.height)
                    )
                    UIImage(cgImage: pill).draw(in: rect)
                }
                self.drawWordmark(in: context)
            }
        }

        func titleCard(_ title: String) -> CGImage? {
            Canvas.picture(size: DuetVideo.size) { context in
                let text = Canvas.text(title, size: DuetVideo.captionSize, weight: .heavy)
                let size = text.size()
                text.draw(at: CGPoint(x: (DuetVideo.size.width - size.width) / 2, y: (DuetVideo.size.height - size.height) / 2))
                self.drawWordmark(in: context)
            }
        }

        func outroCard(_ strip: CGImage) -> CGImage? {
            Canvas.picture(size: DuetVideo.size) { context in
                let room = CGRect(origin: .zero, size: DuetVideo.size)
                    .insetBy(dx: DuetVideo.inset, dy: DuetVideo.inset * 2 + DuetVideo.wordmarkHeight)
                let scale = min(room.width / CGFloat(strip.width), room.height / CGFloat(strip.height))
                let fitted = CGSize(width: CGFloat(strip.width) * scale, height: CGFloat(strip.height) * scale)
                UIImage(cgImage: strip).draw(in: CGRect(
                    x: room.midX - fitted.width / 2, y: room.midY - fitted.height / 2, width: fitted.width, height: fitted.height
                ))
                self.drawWordmark(in: context)
            }
        }

        /// The caption on the clip of the pose: bold white words with a shadow, at the bottom left of the top half.
        func caption(_ title: String) -> CGImage? {
            let text = Canvas.text(title, size: DuetVideo.captionSize, weight: .heavy, shadow: true)
            let size = text.size()
            return Canvas.picture(size: CGSize(width: ceil(size.width) + 32, height: ceil(size.height) + 32)) { _ in
                text.draw(at: CGPoint(x: 16, y: 16))
            }
        }

        /// The divider and the wordmark on a frame of the two clips, with the caption.
        func drawClipOverlay(caption: CGImage?, on context: CGContext) {
            drawDivider(on: context)
            if let caption {
                let height = CGFloat(caption.height)
                Canvas.draw(caption, in: CGRect(
                    x: DuetVideo.inset - 16, y: DuetVideo.poseFrame.maxY - DuetVideo.inset - height + 16,
                    width: CGFloat(caption.width), height: height
                ), on: context)
            }
            drawWordmark(on: context)
        }

        /// A frame of the freeze: the last picture of the pose above the photo, a flash that fades, and the score.
        func drawFreeze(clip: Clip, segment: Segment, at seconds: Double, on context: CGContext) {
            if let last = clip.lastFrame {
                Canvas.draw(last, in: CGRect(origin: .zero, size: DuetVideo.size), on: context)
            }
            if let photo = segment.photo {
                let frame = DuetVideo.attemptFrame
                let shown = CGSize(width: photo.width, height: photo.height)
                let scale = max(frame.width / shown.width, frame.height / shown.height)
                let size = CGSize(width: shown.width * scale, height: shown.height * scale)
                context.saveGState()
                context.clip(to: Canvas.flipped(frame))
                // The photo covers the half; the part below the half is cut, so the faces stay.
                Canvas.draw(photo, in: CGRect(x: frame.midX - size.width / 2, y: frame.minY, width: size.width, height: size.height), on: context)
                context.restoreGState()
            }
            drawDivider(on: context)
            drawWordmark(on: context)
            let afterFlash = seconds - Timing.flash
            if afterFlash < 0 {
                // The flash: white that fades out.
                context.setFillColor(UIColor(white: 1, alpha: 1 - seconds / Timing.flash).cgColor)
                context.fill(CGRect(origin: .zero, size: DuetVideo.size))
            } else if let percent = segment.percent, let pill = pill("\(DuetVideo.countUp(percent: percent, at: afterFlash))%") {
                let scale = DuetVideo.badgeScale(at: afterFlash)
                let size = CGSize(width: CGFloat(pill.width) * scale, height: CGFloat(pill.height) * scale)
                let anchor = CGPoint(x: DuetVideo.size.width - DuetVideo.inset, y: DuetVideo.attemptFrame.minY + DuetVideo.inset)
                Canvas.draw(pill, in: CGRect(x: anchor.x - size.width, y: anchor.y, width: size.width, height: size.height), on: context)
            }
        }

        /// A rounded pill in the accent color with white words. The pills are kept, so each is drawn one time.
        func pill(_ words: String) -> CGImage? {
            if let kept = pills[words] {
                return kept
            }
            let text = Canvas.text(words, size: DuetVideo.badgeSize, weight: .bold)
            let textSize = text.size()
            let size = CGSize(width: ceil(textSize.width) + DuetVideo.badgeSize, height: ceil(textSize.height) + DuetVideo.badgeSize / 3)
            let picture = Canvas.picture(size: size) { context in
                context.setFillColor(self.style.accent)
                context.addPath(CGPath(roundedRect: CGRect(origin: .zero, size: size), cornerWidth: size.height / 2, cornerHeight: size.height / 2, transform: nil))
                context.fillPath()
                text.draw(at: CGPoint(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2))
            }
            pills[words] = picture
            return picture
        }

        private func drawDivider(on context: CGContext) {
            context.setFillColor(UIColor.white.cgColor)
            context.fill(Canvas.flipped(CGRect(
                x: 0, y: DuetVideo.attemptFrame.minY - DuetVideo.divider / 2, width: DuetVideo.size.width, height: DuetVideo.divider
            )))
        }

        /// The wordmark at the bottom right, on a frame.
        private func drawWordmark(on context: CGContext) {
            guard let wordmark else { return }
            Canvas.draw(wordmark, in: wordmarkRect(wordmark), on: context)
        }

        /// The wordmark at the bottom right, in a picture that UIKit draws.
        private func drawWordmark(in _: CGContext) {
            guard let wordmark else { return }
            UIImage(cgImage: wordmark).draw(in: wordmarkRect(wordmark))
        }

        private func wordmarkRect(_ wordmark: CGImage) -> CGRect {
            let height = DuetVideo.wordmarkHeight
            let width = height * CGFloat(wordmark.width) / CGFloat(max(1, wordmark.height))
            return CGRect(
                x: DuetVideo.size.width - DuetVideo.inset - width, y: DuetVideo.size.height - DuetVideo.inset - height,
                width: width, height: height
            )
        }
    }

    // MARK: Clips

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

    /// The transform that puts the upright picture of a clip in a frame of the video. The clip covers the frame,
    /// centered from side to side, with its top at the top of the frame: a cut takes the bottom first, so faces stay
    /// (owner decision, 2026-11-21).
    static func placement(naturalSize: CGSize, transform: CGAffineTransform, in frame: CGRect) -> CGAffineTransform {
        // The stored picture with its own turn or mirror, moved so that its corner is at the origin.
        let shown = CGRect(origin: .zero, size: naturalSize).applying(transform)
        let scale = max(frame.width / shown.width, frame.height / shown.height)
        return transform
            .concatenating(CGAffineTransform(translationX: -shown.minX, y: -shown.minY))
            .concatenating(CGAffineTransform(scaleX: scale, y: scale))
            .concatenating(CGAffineTransform(translationX: frame.midX - shown.width * scale / 2, y: frame.minY))
    }

    // MARK: Results

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
}
