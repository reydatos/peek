import AVFoundation
import CoreGraphics
@testable import Peek
import Testing
import UIKit

struct ClipRecorderTests {
    /// One camera frame with a plain color, at a time on the capture clock.
    func frame(width: Int, height: Int, at seconds: Double) throws -> CMSampleBuffer {
        var pixels: CVPixelBuffer?
        let attributes = [kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary] as CFDictionary
        CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_32BGRA, attributes, &pixels)
        let buffer = try #require(pixels)
        CVPixelBufferLockBaseAddress(buffer, [])
        memset(CVPixelBufferGetBaseAddress(buffer), 0x80, CVPixelBufferGetDataSize(buffer))
        CVPixelBufferUnlockBaseAddress(buffer, [])
        var format: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: nil, imageBuffer: buffer, formatDescriptionOut: &format)
        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 30),
            presentationTimeStamp: CMTime(seconds: 100 + seconds, preferredTimescale: 600),
            decodeTimeStamp: .invalid
        )
        var sample: CMSampleBuffer?
        try CMSampleBufferCreateReadyWithImageBuffer(
            allocator: nil,
            imageBuffer: buffer,
            formatDescription: #require(format),
            sampleTiming: &timing,
            sampleBufferOut: &sample
        )
        return try #require(sample)
    }

    /// Feeds frames at 30 a second until the recorder ends, and gives the still picture.
    func record(to url: URL, rotationAngle: CGFloat, duration: Double, width: Int, height: Int) async throws -> Data {
        let frames = try (0 ... Int(duration * 30) + 5).map { try frame(width: width, height: height, at: Double($0) / 30) }
        nonisolated(unsafe) let unsafeFrames = frames
        return try await withCheckedThrowingContinuation { continuation in
            // H.264 is the codec here: the simulator has no HEVC encoder on each host.
            let recorder = ClipRecorder(url: url, rotationAngle: rotationAngle, duration: duration, codec: .h264) {
                continuation.resume(with: $0)
            }
            for frame in unsafeFrames {
                recorder.append(frame)
                // The writer takes frames in real time; a short wait lets it keep up.
                Thread.sleep(forTimeInterval: 0.002)
            }
        }
    }

    @Test func aClipFromSidewaysFramesIsUprightAndHasItsLength() async throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mov")
        // The camera gives wide 4:3 frames. A quarter turn makes them upright.
        let still = try await record(to: url, rotationAngle: 90, duration: 1, width: 640, height: 480)

        let picture = try #require(UIImage(data: still))
        #expect(abs(picture.size.width / picture.size.height - 0.75) < 0.01)

        let asset = AVURLAsset(url: url)
        let seconds = try await asset.load(.duration).seconds
        #expect(abs(seconds - 1) < 0.2, "the clip is \(seconds) seconds")
        let track = try #require(try await asset.loadTracks(withMediaType: .video).first)
        let (size, transform) = try await track.load(.naturalSize, .preferredTransform)
        let shown = size.applying(transform)
        #expect(abs(shown.width) == 720)
        #expect(abs(shown.height) == 960)
        #expect(try await asset.loadTracks(withMediaType: .audio).isEmpty)
    }

    @Test func aClipFromWideFramesWithNoTurnIsTheCenterColumn() async throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mov")
        let still = try await record(to: url, rotationAngle: 0, duration: 0.5, width: 640, height: 480)
        let picture = try #require(UIImage(data: still))
        // The 3:4 column of a 640 x 480 frame is 360 x 480.
        #expect(picture.size == CGSize(width: 360, height: 480))
        let track = try #require(try await AVURLAsset(url: url).loadTracks(withMediaType: .video).first)
        #expect(try await track.load(.naturalSize) == CGSize(width: 720, height: 960))
    }

    @Test func aRecordingThatStopsGivesAFaultAndNoPicture() async throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mov")
        let first = try frame(width: 640, height: 480, at: 0)
        nonisolated(unsafe) let unsafeFirst = first
        let result: Result<Data, any Error> = await withCheckedContinuation { continuation in
            let recorder = ClipRecorder(url: url, rotationAngle: 90, codec: .h264) { continuation.resume(returning: $0) }
            recorder.append(unsafeFirst)
            recorder.stop()
            // A second stop, or a late frame, does not call the completion again.
            recorder.stop()
            recorder.append(unsafeFirst)
        }
        #expect(throws: ClipRecorder.Failure.self) { try result.get() }
    }

    @Test func theUprightCropIsTheCenterOfThePicture() {
        #expect(ClipRecorder.uprightCrop(of: CGRect(x: 0, y: 0, width: 400, height: 300)) == CGRect(x: 87.5, y: 0, width: 225, height: 300))
        #expect(ClipRecorder.uprightCrop(of: CGRect(x: 0, y: 0, width: 300, height: 400)) == CGRect(x: 0, y: 0, width: 300, height: 400))
        #expect(ClipRecorder.uprightCrop(of: CGRect(x: 0, y: 0, width: 300, height: 600)) == CGRect(x: 0, y: 100, width: 300, height: 400))
    }
}
