import UIKit

/// Takes the line of pixels at one edge of a picture. The outer display draws that line again and again beside
/// the picture, so the background of the picture continues to the edge of the display.
nonisolated enum PictureEdge {
    case left, right, top, bottom

    /// The part of the picture, in pixels, that is the line at this edge.
    func rect(in size: CGSize) -> CGRect {
        switch self {
        case .left: CGRect(x: 0, y: 0, width: 1, height: size.height)
        case .right: CGRect(x: size.width - 1, y: 0, width: 1, height: size.height)
        case .top: CGRect(x: 0, y: 0, width: size.width, height: 1)
        case .bottom: CGRect(x: 0, y: size.height - 1, width: size.width, height: 1)
        }
    }

    /// The largest difference of a color channel along an edge, from 0 to 1, at which the edge is still plain.
    /// This is a design value. The cartoon and 3D pose pictures are below it; the photo pose pictures are above it.
    static let plainLimit = 0.25

    /// True when the line of pixels at this edge has almost one color, as a studio background has.
    /// Such a line can continue to the edge of the display with no visible join. A photo edge makes streaks.
    func isPlain(in image: UIImage) -> Bool {
        guard let line = strip(of: image)?.cgImage else { return false }
        let count = line.width * line.height
        var pixels = [UInt8](repeating: 0, count: count * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: line.width,
                height: line.height,
                bitsPerComponent: 8,
                bytesPerRow: line.width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(line, in: CGRect(x: 0, y: 0, width: line.width, height: line.height))
            return true
        }
        guard drawn, count > 0 else { return false }
        for channel in 0 ..< 3 {
            let values = stride(from: channel, to: pixels.count, by: 4).map { pixels[$0] }
            guard let low = values.min(), let high = values.max() else { return false }
            if Double(high - low) / 255 > Self.plainLimit {
                return false
            }
        }
        return true
    }

    /// The line of pixels at this edge, as a picture. Nil for a picture with no pixels.
    func strip(of image: UIImage) -> UIImage? {
        guard let source = image.cgImage, source.width > 0, source.height > 0 else { return nil }
        let size = CGSize(width: source.width, height: source.height)
        return source.cropping(to: rect(in: size)).map { UIImage(cgImage: $0) }
    }
}
