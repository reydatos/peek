import AVFoundation
@testable import Peek
import Testing
import UIKit

struct DuetVideoTests {
    /// A clip of one color with a frame at each 1/30 second from its start. A rotation angle of 90 gives wide
    /// frames with a quarter turn, as a camera clip has; 0 gives upright frames with no turn.
    ///
    /// The writer waits for the encoder, so it stores each frame. `ClipRecorder` drops a frame when its encoder is
    /// busy, as a live camera must. A drop at the start leaves the clip with no picture there, and the video then
    /// shows no picture of the people at that time: on a busy test machine, that failed this test at random.
    ///
    /// - Parameter firstFrame: the time of the first picture. A later time gives a clip with no picture at its start.
    private func clip(fill: UInt8, duration: Double, rotationAngle: CGFloat = 90, firstFrame: Double = 0) async throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mov")
        let wide = rotationAngle == 90
        let (width, height) = wide ? (640, 480) : (480, 640)
        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: width, AVVideoHeightKey: height,
        ])
        input.expectsMediaDataInRealTime = false
        input.transform = wide ? ClipRecorder.transform(quarterTurns: 1, isMirrored: false) : .identity
        writer.add(input)
        #expect(writer.startWriting())
        // The test frames have their times from 100 seconds.
        writer.startSession(atSourceTime: CMTime(seconds: 100, preferredTimescale: 600))
        for index in Int((firstFrame * 30).rounded()) ..< Int((duration * 30).rounded()) {
            while !input.isReadyForMoreMediaData {
                try await Task.sleep(for: .milliseconds(1))
            }
            #expect(try input.append(ClipRecorderTests().frame(width: width, height: height, at: Double(index) / 30, fill: fill)))
        }
        input.markAsFinished()
        writer.endSession(atSourceTime: CMTime(seconds: 100 + duration, preferredTimescale: 600))
        await writer.finishWriting()
        try #require(writer.status == .completed)
        return url
    }

    /// The brightness of one point of a picture, from 0 to 255. The origin is at the top left.
    private func brightness(of image: CGImage, at point: CGPoint) throws -> Int {
        var pixel = [UInt8](repeating: 0, count: 4)
        let context = try #require(CGContext(
            data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ))
        // The context has its origin at the bottom left.
        context.draw(image, in: CGRect(x: -point.x, y: point.y - CGFloat(image.height) + 1, width: CGFloat(image.width), height: CGFloat(image.height)))
        return (Int(pixel[0]) + Int(pixel[1]) + Int(pixel[2])) / 3
    }

    /// The red, green, and blue of one point of a picture. The origin is at the top left.
    private func color(of image: CGImage, at point: CGPoint) throws -> (red: Int, green: Int, blue: Int) {
        var pixel = [UInt8](repeating: 0, count: 4)
        let context = try #require(CGContext(
            data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ))
        context.draw(image, in: CGRect(x: -point.x, y: point.y - CGFloat(image.height) + 1, width: CGFloat(image.width), height: CGFloat(image.height)))
        return (Int(pixel[0]), Int(pixel[1]), Int(pixel[2]))
    }

    /// The brightest point on a line across the picture, at the height `y`.
    private func brightest(of image: CGImage, alongY y: CGFloat) throws -> Int {
        try stride(from: 16, to: CGFloat(image.width) - 16, by: 4).map { try brightness(of: image, at: CGPoint(x: $0, y: y)) }.max() ?? 0
    }

    /// A picture of one gray value.
    private func solid(width: Int, height: Int, white: CGFloat) throws -> CGImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { context in
            UIColor(white: white, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        return try #require(image.cgImage)
    }

    private let style = DuetVideo.Style(accent: UIColor.red.cgColor, wordmark: nil)

    /// The picture of one frame of a video, in frames from its start.
    private nonisolated static func picture(of url: URL, atFrame frame: Int) async throws -> CGImage {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        return try await generator.image(at: CMTime(value: CMTimeValue(frame), timescale: CMTimeScale(DuetVideo.framesPerSecond))).image
    }

    // The frames of one pose: the title card, the clip part, then the flash and the freeze.
    private let titleFrames = Int((DuetVideo.Timing.title * 30).rounded())
    private let freezeFrames = Int(((DuetVideo.Timing.flash + DuetVideo.Timing.freeze) * 30).rounded())
    private let flashFrames = Int((DuetVideo.Timing.flash * 30).rounded())

    @Test func theVideoIsASplitScreenWithThePoseAboveThePeopleFromEdgeToEdge() async throws {
        // A bright pose clip of 2 seconds and a dark clip of the people of 1 second, both turned; then the reverse,
        // upright with no turn.
        let segments = try await [
            DuetVideo.Segment(pose: clip(fill: 0xE0, duration: 2), attempt: clip(fill: 0x20, duration: 1), title: "POSE 1"),
            DuetVideo.Segment(pose: clip(fill: 0x20, duration: 1, rotationAngle: 0), attempt: clip(fill: 0xE0, duration: 1, rotationAngle: 0), title: "POSE 2"),
        ]
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mp4")
        try await DuetVideo.make(segments, to: url, style: style)

        let asset = AVURLAsset(url: url)
        // Each pose: its title card, the length of the clip of its people, then the flash and the freeze.
        let perPose = titleFrames + 30 + freezeFrames
        #expect(try await abs(asset.load(.duration).seconds - Double(perPose * 2) / 30) < 0.05)
        // One sound track, as long as the picture.
        let sound = try await asset.loadTracks(withMediaType: .audio)
        #expect(sound.count == 1)
        if let soundTrack = sound.first {
            #expect(try await abs(soundTrack.load(.timeRange).duration.seconds - Double(perPose * 2) / 30) < 0.1)
        }
        let track = try #require(try await asset.loadTracks(withMediaType: .video).first)
        #expect(try await track.load(.naturalSize) == DuetVideo.size)
        let first = try await Self.picture(of: url, atFrame: titleFrames + 15)
        // The pose fills the top half to its corners; the people fill the bottom half; a white line is between them.
        #expect(try brightness(of: first, at: CGPoint(x: 8, y: 8)) > 180)
        #expect(try brightness(of: first, at: CGPoint(x: 1072, y: 940)) > 180)
        #expect(try brightness(of: first, at: CGPoint(x: 8, y: 980)) < 80)
        #expect(try brightness(of: first, at: CGPoint(x: 1072, y: 1912)) < 80)
        #expect(try brightness(of: first, at: CGPoint(x: 540, y: DuetVideo.attemptFrame.minY)) > 230)
        let second = try await Self.picture(of: url, atFrame: perPose + titleFrames + 15)
        #expect(try brightness(of: second, at: CGPoint(x: 1072, y: 8)) < 80)
        #expect(try brightness(of: second, at: CGPoint(x: 8, y: 980)) > 180)
        #expect(try brightness(of: second, at: CGPoint(x: 1072, y: 1912)) > 180)
    }

    @Test func eachPoseStartsWithATitleCardAndEndsWithAFlashAndThePhoto() async throws {
        let photo = try solid(width: 1080, height: 1440, white: 0.5)
        let segment = try await DuetVideo.Segment(
            pose: clip(fill: 0xE0, duration: 1), attempt: clip(fill: 0x20, duration: 1), title: "POSE 1", photo: photo
        )
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mp4")
        try await DuetVideo.make([segment], to: url, style: style)

        // The title card: white words on black.
        let card = try await Self.picture(of: url, atFrame: titleFrames / 2)
        #expect(try brightness(of: card, at: CGPoint(x: 8, y: 8)) < 20)
        #expect(try brightest(of: card, alongY: DuetVideo.size.height / 2) > 200)

        // The flash: the first frame after the clips is white.
        let flash = try await Self.picture(of: url, atFrame: titleFrames + 30)
        #expect(try brightness(of: flash, at: CGPoint(x: 540, y: 480)) > 230)
        #expect(try brightness(of: flash, at: CGPoint(x: 540, y: 1440)) > 230)

        // The freeze: the last picture of the pose stays above, and the photo of the shot is below.
        let freeze = try await Self.picture(of: url, atFrame: titleFrames + 30 + flashFrames + 5)
        #expect(try brightness(of: freeze, at: CGPoint(x: 1072, y: 480)) > 180)
        #expect(try abs(brightness(of: freeze, at: CGPoint(x: 540, y: 1440)) - 128) < 20)
    }

    @Test func theScoreShowsInAPillOnlyWhenThePoseHasAScore() async throws {
        let pose = try await clip(fill: 0x20, duration: 0.5)
        let attempt = try await clip(fill: 0x20, duration: 0.5)
        let pillPoint = CGPoint(x: DuetVideo.size.width - DuetVideo.inset - 30, y: DuetVideo.attemptFrame.minY + DuetVideo.inset + 30)
        let lastFrame = titleFrames + 15 + freezeFrames - 1
        for percent in [92, nil] as [Int?] {
            let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mp4")
            try await DuetVideo.make([DuetVideo.Segment(pose: pose, attempt: attempt, title: "POSE 1", percent: percent)], to: url, style: style)
            let end = try await Self.picture(of: url, atFrame: lastFrame)
            let (red, green, _) = try color(of: end, at: pillPoint)
            #expect((red > 180 && green < 80) == (percent != nil), "score \(String(describing: percent))")
        }
    }

    @Test func theScoreCountsUpThenPops() {
        #expect(DuetVideo.countUp(percent: 92, at: 0) == 0)
        #expect(DuetVideo.countUp(percent: 92, at: DuetVideo.Timing.countUp / 2) == 46)
        #expect(DuetVideo.countUp(percent: 92, at: DuetVideo.Timing.countUp) == 92)
        #expect(DuetVideo.countUp(percent: 92, at: DuetVideo.Timing.freeze) == 92)
        #expect(DuetVideo.badgeScale(at: DuetVideo.Timing.countUp / 2) == 1)
        let middleOfPop = (DuetVideo.Timing.countUp + DuetVideo.Timing.freeze) / 2
        #expect(DuetVideo.badgeScale(at: middleOfPop) > 1.15)
        #expect(abs(DuetVideo.badgeScale(at: DuetVideo.Timing.freeze) - 1) < 0.01)
    }

    @Test func theStoryAddsAnIntroCardAndTheStripAsTheLastShot() async throws {
        let strip = try solid(width: 400, height: 1200, white: 1)
        let segment = try await DuetVideo.Segment(pose: clip(fill: 0x20, duration: 0.5), attempt: clip(fill: 0x20, duration: 0.5), title: "POSE 1")
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mp4")
        try await DuetVideo.make([segment], story: .init(title: "Test pack", subtitle: "DUET", strip: strip), to: url, style: style)

        let intro = Int((DuetVideo.Timing.intro * 30).rounded())
        let outro = Int((DuetVideo.Timing.outro * 30).rounded())
        let total = intro + titleFrames + 15 + freezeFrames + outro
        let asset = AVURLAsset(url: url)
        #expect(try await abs(asset.load(.duration).seconds - Double(total) / 30) < 0.05)
        let first = try await Self.picture(of: url, atFrame: intro / 2)
        #expect(try brightness(of: first, at: CGPoint(x: 8, y: 8)) < 20)
        // The subtitle pill is in the accent color, below the title, in the middle.
        let reds = try stride(from: DuetVideo.size.height / 2, to: DuetVideo.size.height * 0.75, by: 8).map {
            try color(of: first, at: CGPoint(x: DuetVideo.size.width / 2, y: $0))
        }
        #expect(reds.contains { $0.red > 180 && $0.green < 80 })
        let last = try await Self.picture(of: url, atFrame: total - 5)
        #expect(try brightness(of: last, at: CGPoint(x: DuetVideo.size.width / 2, y: DuetVideo.size.height / 2)) > 230)
        #expect(try brightness(of: last, at: CGPoint(x: 8, y: 8)) < 20)
    }

    @Test func theProgressGrowsToTheEnd() async throws {
        final nonisolated class Values: @unchecked Sendable {
            private let lock = NSLock()
            private var all: [Double] = []
            func add(_ value: Double) {
                lock.withLock { all.append(value) }
            }

            var list: [Double] {
                lock.withLock { all }
            }
        }
        let values = Values()
        let segment = try await DuetVideo.Segment(pose: clip(fill: 0x20, duration: 0.5), attempt: clip(fill: 0xE0, duration: 0.5), title: "POSE 1")
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mp4")
        try await DuetVideo.make([segment], to: url, style: style) { values.add($0) }
        let list = values.list
        #expect(!list.isEmpty)
        #expect(zip(list, list.dropFirst()).allSatisfy { $0 <= $1 })
        #expect(abs((list.last ?? 0) - 1) < 0.001)
    }

    @Test func theSoundsMarkEachCountdownSecondTheShutterAndTheScore() {
        // An intro, then a pose with a clip of 3 s and a score, then a pose with a clip of 2.5 s and no score.
        let cues = DuetVideo.cues(intro: true, clipFrames: [90, 75], percents: [92, nil])
        // The video counts in whole frames, so the expected times do too.
        let intro = Double(DuetVideo.frames(DuetVideo.Timing.intro)) / 30
        let title = Double(DuetVideo.frames(DuetVideo.Timing.title)) / 30
        let freeze = Double(DuetVideo.frames(DuetVideo.Timing.flash + DuetVideo.Timing.freeze)) / 30
        let firstEnd = intro + title + 3
        let secondEnd = firstEnd + freeze + title + 2.5
        let expected: [DuetVideo.Cue] = [
            .init(kind: .beep, time: firstEnd - 3), .init(kind: .beep, time: firstEnd - 2), .init(kind: .beep, time: firstEnd - 1),
            .init(kind: .shutter, time: firstEnd),
            .init(kind: .pop, time: firstEnd + DuetVideo.Timing.flash + DuetVideo.Timing.countUp),
            // A clip of 2.5 s counts "3, 2, 1" too, but its first beep would be before the clip: it lost its start.
            .init(kind: .beep, time: secondEnd - 2), .init(kind: .beep, time: secondEnd - 1),
            .init(kind: .shutter, time: secondEnd),
        ]
        #expect(cues.count == expected.count)
        for (cue, want) in zip(cues, expected) {
            #expect(cue.kind == want.kind && abs(cue.time - want.time) < 0.001, "\(cue) is not \(want)")
        }
    }

    @Test func eachSoundIsShortAndQuiet() {
        for kind in [DuetVideo.Cue.Kind.beep, .shutter, .pop] {
            let samples = DuetVideo.Sound.sound(kind)
            #expect(!samples.isEmpty && samples.count < DuetVideo.Sound.sampleRate / 5, "\(kind)")
            #expect(samples.allSatisfy { abs($0) <= 0.5 }, "\(kind)")
        }
    }

    @Test func theShutterSoundsAtTheFlashAndTheTitleCardIsSilent() async throws {
        let segment = try await DuetVideo.Segment(pose: clip(fill: 0x20, duration: 1), attempt: clip(fill: 0xE0, duration: 1), title: "POSE 1")
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mp4")
        try await DuetVideo.make([segment], to: url, style: style)

        // Read the sound back as numbers, one channel.
        let asset = AVURLAsset(url: url)
        let track = try #require(try await asset.loadTracks(withMediaType: .audio).first)
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
            AVFormatIDKey: kAudioFormatLinearPCM, AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false, AVLinearPCMIsNonInterleaved: false, AVNumberOfChannelsKey: 1,
        ])
        reader.add(output)
        #expect(reader.startReading())
        var samples: [Int16] = []
        while let buffer = output.copyNextSampleBuffer(), let block = CMSampleBufferGetDataBuffer(buffer) {
            var length = 0
            var pointer: UnsafeMutablePointer<CChar>?
            CMBlockBufferGetDataPointer(block, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &pointer)
            if let pointer {
                pointer.withMemoryRebound(to: Int16.self, capacity: length / 2) { samples.append(contentsOf: UnsafeBufferPointer(start: $0, count: length / 2)) }
            }
        }
        func loudest(from start: Double, to end: Double) -> Int {
            let rate = Double(DuetVideo.Sound.sampleRate)
            let range = max(0, Int(start * rate)) ..< min(samples.count, Int(end * rate))
            return range.isEmpty ? 0 : samples[range].map { abs(Int($0)) }.max() ?? 0
        }
        let flash = DuetVideo.Timing.title + 1
        #expect(loudest(from: flash, to: flash + 0.1) > 3000)
        #expect(loudest(from: 0.1, to: DuetVideo.Timing.title - 0.1) < 300)
    }

    @Test func aClipWithNoPictureAtItsStartLeavesNoPanelEmpty() async throws {
        // A recorder that dropped its first frames: the bright clip of the people has its first picture at 0.6 s.
        let segment = try await DuetVideo.Segment(
            pose: clip(fill: 0x20, duration: 1, rotationAngle: 0),
            attempt: clip(fill: 0xE0, duration: 1, rotationAngle: 0, firstFrame: 0.6),
            title: "POSE 1"
        )
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mp4")
        try await DuetVideo.make([segment], to: url, style: style)

        // The pose has the length of the part of the clip that has a picture, and the panel shows the people at once.
        let asset = AVURLAsset(url: url)
        #expect(try await abs(asset.load(.duration).seconds - Double(titleFrames + 12 + freezeFrames) / 30) < 0.1)
        let start = try await Self.picture(of: url, atFrame: titleFrames + 1)
        #expect(try brightness(of: start, at: CGPoint(x: DuetVideo.attemptFrame.midX, y: DuetVideo.attemptFrame.midY)) > 180)
    }

    @Test func aVideoThatTakesTooLongStopsWithAFaultAndLeavesNoFile() async throws {
        let segments = try await [
            DuetVideo.Segment(pose: clip(fill: 0x20, duration: 1), attempt: clip(fill: 0xE0, duration: 1), title: "POSE 1"),
            DuetVideo.Segment(pose: clip(fill: 0xE0, duration: 1), attempt: clip(fill: 0x20, duration: 1), title: "POSE 2"),
        ]
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mp4")
        await #expect(throws: DuetVideo.Failure.timeout) {
            try await DuetVideo.make(segments, to: url, style: style, timeout: .zero)
        }
        #expect(!FileManager.default.fileExists(atPath: url.path))

        // A video after the one that stopped is made as usual.
        try await DuetVideo.make(segments, to: url, style: style)
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    @Test func aVideoWithNoPoseIsAFault() async {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mp4")
        await #expect(throws: DuetVideo.Failure.self) { try await DuetVideo.make([], to: url, style: style) }
    }

    @Test func thePlacementCoversTheHalfAndKeepsTheTopOfAnUprightClip() {
        let frame = DuetVideo.attemptFrame
        let stored = CGSize(width: 960, height: 720)
        // A quarter turn, and the mirror of a selfie clip: an upright picture, 720 x 960 as shown.
        for transform in [ClipRecorder.transform(quarterTurns: 1, isMirrored: false), ClipRecorder.transform(quarterTurns: 1, isMirrored: true)] {
            let placed = CGRect(origin: .zero, size: stored).applying(DuetVideo.placement(naturalSize: stored, transform: transform, in: frame))
            // It covers the width; its top is at the top of the half; the part below the half is cut.
            #expect(abs(placed.minX - frame.minX) < 0.5 && abs(placed.width - frame.width) < 0.5)
            #expect(abs(placed.minY - frame.minY) < 0.5 && placed.height > frame.height)
        }
        // A wide picture with no turn covers the height and is centered from side to side.
        let wide = CGRect(origin: .zero, size: stored).applying(DuetVideo.placement(naturalSize: stored, transform: .identity, in: frame))
        #expect(abs(wide.minY - frame.minY) < 0.5 && abs(wide.height - frame.height) < 0.5)
        #expect(abs(wide.midX - frame.midX) < 0.5 && wide.width > frame.width)
    }
}
