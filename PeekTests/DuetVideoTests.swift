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
    private func clip(fill: UInt8, duration: Double, rotationAngle: CGFloat = 90) async throws -> URL {
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
        for index in 0 ..< Int((duration * 30).rounded()) {
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

    @Test func theVideoHasThePoseClipAboveTheClipOfThePeople() async throws {
        // A bright pose clip of 2 seconds and a dark clip of the people of 1 second; then the reverse, with no turn.
        let segments = try await [
            DuetVideo.Segment(pose: clip(fill: 0xE0, duration: 2), attempt: clip(fill: 0x20, duration: 1), label: "Pose 1"),
            DuetVideo.Segment(pose: clip(fill: 0x20, duration: 1, rotationAngle: 0), attempt: clip(fill: 0xE0, duration: 1, rotationAngle: 0), label: "Pose 2"),
        ]
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mp4")
        let paper = UIColor(white: 0.5, alpha: 1).cgColor
        try await DuetVideo.make(segments, to: url, style: .init(paper: paper, ink: UIColor.black.cgColor, wordmark: nil))

        let asset = AVURLAsset(url: url)
        // Each pose has the length of the clip of its people.
        #expect(try await abs(asset.load(.duration).seconds - 2) < 0.3)
        #expect(try await asset.loadTracks(withMediaType: .audio).isEmpty)
        let track = try #require(try await asset.loadTracks(withMediaType: .video).first)
        #expect(try await track.load(.naturalSize) == DuetVideo.size)

        let generator = AVAssetImageGenerator(asset: asset)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        let pose = CGPoint(x: DuetVideo.poseFrame.midX, y: DuetVideo.poseFrame.midY)
        let attempt = CGPoint(x: DuetVideo.attemptFrame.midX, y: DuetVideo.attemptFrame.midY)
        let first = try await generator.image(at: CMTime(seconds: 0.5, preferredTimescale: 600)).image
        #expect(try brightness(of: first, at: pose) > 180)
        #expect(try brightness(of: first, at: attempt) < 80)
        // The clips cover their frames to the corners, and the paper is beside them.
        #expect(try brightness(of: first, at: CGPoint(x: DuetVideo.poseFrame.minX + 8, y: DuetVideo.poseFrame.minY + 8)) > 180)
        #expect(try brightness(of: first, at: CGPoint(x: DuetVideo.poseFrame.maxX - 8, y: DuetVideo.poseFrame.maxY - 8)) > 180)
        #expect(try abs(brightness(of: first, at: CGPoint(x: 40, y: 400)) - 128) < 30)
        let second = try await generator.image(at: CMTime(seconds: 1.5, preferredTimescale: 600)).image
        #expect(try brightness(of: second, at: pose) < 80)
        #expect(try brightness(of: second, at: attempt) > 180)
        #expect(try brightness(of: second, at: CGPoint(x: DuetVideo.attemptFrame.maxX - 8, y: DuetVideo.attemptFrame.maxY - 8)) > 180)
    }

    @Test func theCoverHasOpeningsForTheTwoClipsAndPaperBesideThem() throws {
        let cover = try #require(DuetVideo.cover(label: "Pose 1", style: .init(paper: UIColor.white.cgColor, ink: UIColor.black.cgColor, wordmark: nil)))
        #expect(CGSize(width: cover.width, height: cover.height) == DuetVideo.size)
        // An opening has no color, so the context keeps its black. The paper is white.
        #expect(try brightness(of: cover, at: CGPoint(x: DuetVideo.poseFrame.midX, y: DuetVideo.poseFrame.midY)) == 0)
        #expect(try brightness(of: cover, at: CGPoint(x: DuetVideo.attemptFrame.midX, y: DuetVideo.attemptFrame.midY)) == 0)
        #expect(try brightness(of: cover, at: CGPoint(x: 40, y: 400)) == 255)
    }

    @Test func aVideoWithNoPoseIsAFault() async {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mp4")
        let style = DuetVideo.Style(paper: UIColor.white.cgColor, ink: UIColor.black.cgColor, wordmark: nil)
        await #expect(throws: DuetVideo.Failure.self) { try await DuetVideo.make([], to: url, style: style) }
    }

    @Test func thePlacementPutsATurnedClipAndAMirrorClipInTheFrame() {
        let frame = DuetVideo.attemptFrame
        let stored = CGSize(width: 960, height: 720)
        // A quarter turn, and the mirror of a selfie clip.
        for transform in [ClipRecorder.transform(quarterTurns: 1, isMirrored: false), ClipRecorder.transform(quarterTurns: 1, isMirrored: true)] {
            let placed = CGRect(origin: .zero, size: stored).applying(DuetVideo.placement(naturalSize: stored, transform: transform, in: frame))
            #expect(abs(placed.minX - frame.minX) < 0.5 && abs(placed.minY - frame.minY) < 0.5)
            #expect(abs(placed.width - frame.width) < 0.5 && abs(placed.height - frame.height) < 0.5)
        }
    }
}
