import CoreVideo
import UIKit

extension DuetVideo {
    /// Drawing for the duet video. A rectangle here has its origin at the top left of the video, as in UIKit.
    nonisolated enum Canvas {
        /// Lets `body` draw on a frame. The context has the origin of Core Graphics, at the bottom left.
        static func with(_ buffer: CVPixelBuffer, _ body: (CGContext) -> Void) {
            CVPixelBufferLockBaseAddress(buffer, [])
            defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
            guard let context = CGContext(
                data: CVPixelBufferGetBaseAddress(buffer),
                width: CVPixelBufferGetWidth(buffer),
                height: CVPixelBufferGetHeight(buffer),
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            ) else { return }
            body(context)
        }

        /// A copy of a frame as a picture.
        static func image(of buffer: CVPixelBuffer) -> CGImage? {
            var image: CGImage?
            with(buffer) { image = $0.makeImage() }
            return image
        }

        /// A rectangle of the video in the coordinates of a frame context.
        static func flipped(_ rect: CGRect) -> CGRect {
            CGRect(x: rect.minX, y: DuetVideo.size.height - rect.maxY, width: rect.width, height: rect.height)
        }

        /// Draws a picture upright in a rectangle of the video.
        static func draw(_ image: CGImage, in rect: CGRect, on context: CGContext) {
            context.draw(image, in: flipped(rect))
        }

        /// A transparent picture that UIKit draws, with the origin at the top left.
        static func picture(size: CGSize, _ draw: (CGContext) -> Void) -> CGImage? {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            format.opaque = false
            return UIGraphicsImageRenderer(size: size, format: format).image { draw($0.cgContext) }.cgImage
        }

        /// White words in the system font.
        static func text(_ words: String, size: CGFloat, weight: UIFont.Weight, shadow: Bool = false) -> NSAttributedString {
            var attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size, weight: weight),
                .foregroundColor: UIColor.white,
            ]
            if shadow {
                // The caption is on a clip of any color, so a soft shadow keeps it readable.
                let shade = NSShadow()
                shade.shadowColor = UIColor.black.withAlphaComponent(0.5)
                shade.shadowBlurRadius = 12
                shade.shadowOffset = CGSize(width: 0, height: 4)
                attributes[.shadow] = shade
            }
            return NSAttributedString(string: words, attributes: attributes)
        }

        /// A white copy of a picture with the same shape: the wordmark on the clips.
        static func white(_ image: CGImage) -> CGImage? {
            let size = CGSize(width: image.width, height: image.height)
            return picture(size: size) { context in
                UIImage(cgImage: image).draw(in: CGRect(origin: .zero, size: size))
                context.setBlendMode(.sourceIn)
                context.setFillColor(UIColor.white.cgColor)
                context.fill(CGRect(origin: .zero, size: size))
            }
        }
    }
}
