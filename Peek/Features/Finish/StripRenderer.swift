import PeekCore
import UIKit

/// Draws the finished picture: the accepted shots on photo paper, with a footer.
/// The vertical strip has one column. The 2x2 layout has two.
///
/// The sizes are design values. PRD M3 asks for 600 x 1800 pixels or more for the strip; four shots give
/// 1200 x 3744. The PRD gives no size for 2x2; the same cells give 2352 x 1992.
/// Pose reference pictures are never drawn here.
nonisolated enum StripRenderer {
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

    /// The values that come from the main actor: the paper colors and the wordmark.
    /// The strip is a picture, so its colors are the same in light mode and in dark mode.
    struct Style: Sendable {
        let paper: UIColor
        let ink: UIColor
        let wordmark: UIImage?

        @MainActor static var current: Style {
            Style(
                paper: UIColor(PeekTheme.photoPaper),
                ink: UIColor(PeekTheme.paperInk),
                wordmark: UIImage(named: "peek-wordmark")?.withTintColor(UIColor(PeekTheme.paperWordmark), renderingMode: .alwaysOriginal)
            )
        }
    }

    @MainActor static func render(_ shots: [UIImage], layout: PeekCore.Layout = .verticalStrip, date: Date = .now) -> UIImage {
        draw(shots, layout: layout, date: date, style: .current)
    }

    /// Draws the picture off the main actor, so the decode of the full-size shots does not stop the interface.
    @concurrent static func renderInBackground(_ shots: [UIImage], layout: PeekCore.Layout, date: Date = .now, style: Style) async -> UIImage {
        draw(shots, layout: layout, date: date, style: style)
    }

    private static func draw(_ shots: [UIImage], layout: PeekCore.Layout, date: Date, style: Style) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let size = size(shotCount: shots.count, layout: layout)
        let columns = columns(shotCount: shots.count, layout: layout)
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            style.paper.setFill()
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
                style: style,
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

    private static func drawFooter(date: Date, style: Style, in frame: CGRect) {
        let ink = style.ink
        let dateFont = UIFont.systemFont(ofSize: footer / 6, weight: .semibold)
        let day = NSAttributedString(
            string: date.formatted(date: .abbreviated, time: .omitted),
            attributes: [.font: dateFont, .foregroundColor: ink]
        )
        // The PEEK wordmark, one third of the footer height.
        if let wordmark = style.wordmark, wordmark.size.height > 0 {
            let height = footer / 3
            let width = height * wordmark.size.width / wordmark.size.height
            wordmark.draw(in: CGRect(x: frame.minX, y: frame.midY - height / 2, width: width, height: height))
        }
        day.draw(at: CGPoint(x: frame.maxX - day.size().width, y: frame.midY - day.size().height / 2))
    }
}
