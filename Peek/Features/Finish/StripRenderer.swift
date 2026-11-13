import PeekCore
import UIKit

/// Draws the finished picture: the accepted shots on cream paper, with a footer.
/// The vertical strip has one column. The 2x2 layout has two.
///
/// The sizes are design values. PRD M3 asks for 600 x 1800 pixels or more for the strip; four shots give
/// 1200 x 3744. The PRD gives no size for 2x2; the same cells give 2352 x 1992.
/// Pose reference pictures are never drawn here.
enum StripRenderer {
    static let margin: CGFloat = 48
    static let footer: CGFloat = 192
    /// Each shot is cropped to 4:3.
    static let cell = CGSize(width: 1104, height: 828)

    static func columns(shotCount: Int, layout: PeekCore.Layout) -> Int {
        layout == .grid2x2 ? max(1, min(2, shotCount)) : 1
    }

    static func size(shotCount: Int, layout: PeekCore.Layout = .verticalStrip) -> CGSize {
        let columns = columns(shotCount: shotCount, layout: layout)
        let rows = (shotCount + columns - 1) / columns
        return CGSize(
            width: margin + CGFloat(columns) * (cell.width + margin),
            height: margin + CGFloat(rows) * (cell.height + margin) + footer
        )
    }

    static func render(_ shots: [UIImage], layout: PeekCore.Layout = .verticalStrip, date: Date = .now) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let size = size(shotCount: shots.count, layout: layout)
        let columns = columns(shotCount: shots.count, layout: layout)
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor(PeekTheme.cream).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            for (index, shot) in shots.enumerated() {
                let frame = CGRect(
                    origin: CGPoint(
                        x: margin + CGFloat(index % columns) * (cell.width + margin),
                        y: margin + CGFloat(index / columns) * (cell.height + margin)
                    ),
                    size: cell
                )
                draw(shot, filling: frame, in: context.cgContext)
            }
            drawFooter(
                date: date,
                in: CGRect(x: margin, y: size.height - footer, width: size.width - 2 * margin, height: footer)
            )
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
