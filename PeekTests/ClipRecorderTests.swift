import AVFoundation
import CoreGraphics
@testable import Peek
import Testing
import UIKit

struct ClipRecorderTests {
    /// One camera frame with a plain color, at a time on the capture clock.
    func frame(width: Int, height: Int, at seconds: Double, fill: UInt8 = 0x80) throws -> CMSampleBuffer {
        var pixels: CVPixelBuffer?
        let attributes = [kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary] as CFDictionary
        CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_32BGRA, attributes, &pixels)
        let buffer = try #require(pixels)
        CVPixelBufferLockBaseAddress(buffer, [])
        memset(CVPixelBufferGetBaseAddress(buffer), Int32(fill), CVPixelBufferGetDataSize(buffer))
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
    func record(to url: URL, rotationAngle: CGFloat, duration: Double, width: Int, height: Int, fill: UInt8 = 0x80) async throws -> Data {
        let frames = try (0 ... Int(duration * 30) + 5).map { try frame(width: width, height: height, at: Double($0) / 30, fill: fill) }
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

    @Test func aSelfieClipIsAMirrorPicture() throws {
        // A frame with the left half bright and the right half dark.
        var pixels: CVPixelBuffer?
        CVPixelBufferCreate(nil, 480, 640, kCVPixelFormatType_32BGRA, nil, &pixels)
        let buffer = try #require(pixels)
        CVPixelBufferLockBaseAddress(buffer, [])
        let base = try #require(CVPixelBufferGetBaseAddress(buffer))
        let rowBytes = CVPixelBufferGetBytesPerRow(buffer)
        for row in 0 ..< 640 {
            memset(base + row * rowBytes, 0xFF, 240 * 4)
            // Black with full alpha. A pixel with no alpha becomes white in a JPEG.
            let dark = (base + row * rowBytes + 240 * 4).bindMemory(to: UInt32.self, capacity: 240)
            for column in 0 ..< 240 {
                dark[column] = 0xFF00_0000
            }
        }
        CVPixelBufferUnlockBaseAddress(buffer, [])

        func leftIsBright(_ data: Data?) throws -> Bool {
            let bytes = try #require(data)
            let image = try #require(UIImage(data: bytes)?.cgImage)
            // The complete picture goes into two pixels: the left half and the right half.
            var pixel = [UInt8](repeating: 0, count: 8)
            let context = try #require(CGContext(
                data: &pixel, width: 2, height: 1, bitsPerComponent: 8, bytesPerRow: 8,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            ))
            context.draw(image, in: CGRect(x: 0, y: 0, width: 2, height: 1))
            return pixel[0] > pixel[4]
        }
        #expect(try leftIsBright(ClipRecorder.still(of: buffer, quarterTurns: 0)))
        #expect(try !leftIsBright(ClipRecorder.still(of: buffer, quarterTurns: 0, isMirrored: true)))

        // The clip stores the same flip, after the rotation that makes it upright.
        let point = CGPoint(x: 1, y: 0)
        #expect(point.applying(ClipRecorder.transform(quarterTurns: 0, isMirrored: true)).x == -1)
        #expect(ClipRecorder.transform(quarterTurns: 0, isMirrored: false) == .identity)
        let turned = point.applying(ClipRecorder.transform(quarterTurns: 1, isMirrored: true))
        #expect(abs(turned.x) < 0.0001 && abs(turned.y - 1) < 0.0001)
    }
}
