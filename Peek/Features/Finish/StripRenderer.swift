import UIKit

/// Draws the finished strip: the accepted shots in a column on cream paper, with a footer.
///
/// The sizes are design values. PRD M3 asks for 600 x 1800 pixels or more; four shots give 1200 x 3744.
/// Pose reference pictures are never drawn here.
enum StripRenderer {
    static let width: CGFloat = 1200
    static let margin: CGFloat = 48
    static let footer: CGFloat = 192
    /// Each shot is cropped to 4:3.
    static let cell = CGSize(width: width - 2 * margin, height: (width - 2 * margin) * 3 / 4)

    static func size(shotCount: Int) -> CGSize {
        CGSize(width: width, height: margin + CGFloat(shotCount) * (cell.height + margin) + footer)
    }

    static func render(_ shots: [UIImage], date: Date = .now) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let size = size(shotCount: shots.count)
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor(PeekTheme.cream).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            for (index, shot) in shots.enumerated() {
                let frame = CGRect(
                    origin: CGPoint(x: margin, y: margin + CGFloat(index) * (cell.height + margin)),
                    size: cell
                )
                draw(shot, filling: frame, in: context.cgContext)
            }
            drawFooter(date: date, in: CGRect(x: margin, y: size.height - footer, width: cell.width, height: footer))
        }
    }

    /// Draws the image to cover the frame, centered, with the overflow clipped.
    private static func draw(_ image: UIImage, filling frame: CGRect, in context: CGContext) {
        guard image.size.width > 0, image.size.height > 0 else { return }
        let scale = max(frame.width / image.size.width, frame.height / image.size.height)
        let drawn = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        context.saveGState()
        context.clip(to: frame)
        image.draw(in: CGRect(
            x: frame.midX - drawn.width / 2,
            y: frame.midY - drawn.height / 2,
            width: drawn.width,
            height: drawn.height
        ))
        context.restoreGState()
    }

    private static func drawFooter(date: Date, in frame: CGRect) {
        let ink = UIColor(PeekTheme.ink)
        let titleFont = UIFont(name: "InstrumentSerif-Italic", size: footer / 2)
            ?? .italicSystemFont(ofSize: footer / 2)
        let dateFont = UIFont(name: PeekFont.sansName, size: footer / 6) ?? .systemFont(ofSize: footer / 6)
        let title = NSAttributedString(string: "Peek", attributes: [.font: titleFont, .foregroundColor: ink])
        let day = NSAttributedString(
            string: date.formatted(date: .abbreviated, time: .omitted),
            attributes: [.font: dateFont, .foregroundColor: ink]
        )
        title.draw(at: CGPoint(x: frame.minX, y: frame.midY - title.size().height / 2))
        day.draw(at: CGPoint(x: frame.maxX - day.size().width, y: frame.midY - day.size().height / 2))
    }
}
