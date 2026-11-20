import AVFoundation
import ImageIO
import PeekCore
import UniformTypeIdentifiers

/// Examines the pictures and the clips of a pack file from a different phone, before the app stores them.
/// The app accepts only what its own recorder makes: a JPEG picture, and a short silent clip.
nonisolated enum PackMediaCheck {
    /// The longest side of a picture, in pixels. This is a design value.
    static let maximumPictureSide = 4096
    /// A clip can be this much longer than the clip of the recorder, in seconds. This is a design value.
    static let lengthTolerance = 1.0
    /// The longest side of a clip, in pixels. The recorder makes 720 x 960. This is a design value.
    static let maximumClipSide = 1920.0
    /// The largest frame rate of a clip, in frames each second. This is a design value.
    static let maximumFrameRate: Float = 60

    static func isUsable(_ file: PackFile) async -> Bool {
        for pose in file.poses {
            guard isPicture(pose.still), await isClip(pose.clip) else { return false }
        }
        return true
    }

    /// True for one JPEG picture of a sensible size. The check reads the header only; it does not draw the picture.
    static func isPicture(_ data: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetType(source) as String? == UTType.jpeg.identifier,
              CGImageSourceGetCount(source) == 1,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int
        else { return false }
        return (1 ... maximumPictureSide).contains(width) && (1 ... maximumPictureSide).contains(height)
    }

    /// True for a clip that plays, has one video track and no sound track, is not longer than a pose clip,
    /// and is not larger or faster than the players of the app are made for.
    static func isClip(_ data: Data) async -> Bool {
        let url = FileManager.default.temporaryDirectory.appending(path: "check-\(UUID().uuidString).mov")
        defer { try? FileManager.default.removeItem(at: url) }
        guard (try? data.write(to: url)) != nil else { return false }
        let asset = AVURLAsset(url: url)
        guard let isPlayable = try? await asset.load(.isPlayable), isPlayable,
              let duration = try? await asset.load(.duration),
              let video = try? await asset.loadTracks(withMediaType: .video), video.count == 1,
              let audio = try? await asset.loadTracks(withMediaType: .audio), audio.isEmpty,
              let track = video.first,
              let size = try? await track.load(.naturalSize),
              let rate = try? await track.load(.nominalFrameRate),
              size.width > 0, size.height > 0, max(size.width, size.height) <= maximumClipSide,
              rate <= maximumFrameRate
        else { return false }
        let seconds = duration.seconds
        return seconds > 0 && seconds <= ClipRecorder.duration + lengthTolerance
    }
}
