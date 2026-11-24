import PeekCore
import UIKit

/// Draws the finished picture: the accepted shots on photo paper, with a footer.
/// The vertical strip has one column. The 2x2 layout has two.
/// The duet prints put the pose pictures above the shots: `duetRow` has the poses in one row and the shots in
/// the row below; `duetSingle` has one pose above its shot. Only the duet prints draw pose pictures.
///
/// The sizes are design values. PRD M3 asks for 600 x 1800 pixels or more for the strip; four shots give
/// 1200 x 3744. The PRD gives no size for 2x2; the same cells give 2352 x 1992.
/// The duet cells are 3:4 like the pose pictures, so a pose is drawn whole: four shots give 3552 x 2640 for
/// `duetRow`, and one shot gives 1200 x 3280 for `duetSingle`. The wide `duetRow` has a taller footer, so its
/// score and verdict can be read in a group chat.
/// With scores on, a duet print puts the score of each shot on the shot, and `duetRow` marks the best copy.
nonisolated enum StripRenderer {
    static let margin: CGFloat = 48
    static let footer: CGFloat = 192
    /// Each shot is cropped to 4:3.
    static let cell = CGSize(width: 1104, height: 828)
    /// The shape of one shot in the finished picture: the width divided by the height.
    static var cellAspect: CGFloat {
        cell.width / cell.height
    }

    /// A cell of `duetRow`: 3:4, the shape of a pose picture.
    static let duetCell = CGSize(width: 828, height: 1104)
    /// A cell of `duetSingle`: 3:4, as wide as a strip cell.
    static let singleCell = CGSize(width: 1104, height: 1472)
    /// The width of the cyan line around a pose picture. A design value, as the reference frame of the booth.
    static let poseBorder: CGFloat = 12
    /// The width of the line around each shot. A design value (owner decision, 2026-11-23: black lines on cream
    /// and on white, white lines on black, as a photo booth print).
    static let shotBorder: CGFloat = 8
    /// The footer of the wide duet row. A design value: 1.5 times the footer of the strip.
    static let wideFooter: CGFloat = 288

    static func footerHeight(for layout: PeekCore.Layout) -> CGFloat {
        layout == .duetRow ? wideFooter : footer
    }

    static func columns(shotCount: Int, layout: PeekCore.Layout) -> Int {
        switch layout {
        case .verticalStrip, .duetSingle: 1
        case .grid2x2: max(1, min(2, shotCount))
        case .duetRow: max(1, shotCount)
        }
    }

    static func rows(shotCount: Int, layout: PeekCore.Layout) -> Int {
        if layout.showsPoses {
            return 2
        }
        let columns = columns(shotCount: shotCount, layout: layout)
        return (shotCount + columns - 1) / columns
    }

    static func cellSize(for layout: PeekCore.Layout) -> CGSize {
        switch layout {
        case .verticalStrip, .grid2x2: cell
        case .duetRow: duetCell
        case .duetSingle: singleCell
        }
    }

    static func size(shotCount: Int, layout: PeekCore.Layout = .verticalStrip) -> CGSize {
        let columns = columns(shotCount: shotCount, layout: layout)
        let rows = rows(shotCount: shotCount, layout: layout)
        let cell = cellSize(for: layout)
        return CGSize(
            width: margin + CGFloat(columns) * (cell.width + margin),
            height: margin + CGFloat(rows) * (cell.height + margin) + footerHeight(for: layout)
        )
    }

    /// A pose of a duet print: its reference picture, its name for a pose that has no picture, and the match of
    /// the shot of this pose, in percent.
    struct DuetPose: Sendable {
        let picture: UIImage?
        let name: String
        var percent: Int?
    }

    /// The index of the best copy: the highest score, the first of equal scores. Nil with fewer than two scores,
    /// because one shot is not a contest.
    static func bestIndex(_ percents: [Int?]) -> Int? {
        let scored = percents.indices.compactMap { index in percents[index].map { (index, $0) } }
        guard scored.count >= 2 else { return nil }
        return scored.max { $0.1 < $1.1 || ($0.1 == $1.1 && $0.0 > $1.0) }?.0
    }

    /// The values that come from the main actor: the paper colors and the wordmark.
    /// The strip is a picture, so its colors are the same in light mode and in dark mode.
    struct Style: Sendable {
        let paper: UIColor
        let ink: UIColor
        let wordmark: UIImage?
        /// The line around a pose picture in a duet print.
        let poseLine: UIColor
        /// The line around each shot: black on cream and on white, white on black.
        let shotLine: UIColor
        /// The score on a shot: white, with dark words, on every paper.
        let pill: UIColor
        let pillInk: UIColor
        /// The tag of the best copy: red, with white words and a crown.
        let tag: UIColor
        let crown: UIImage?
        let bestCopy: String

        @MainActor static func paper(_ frame: FrameColor) -> Style {
            let paper = switch frame {
            case .cream: PeekTheme.photoPaper
            case .white: PeekTheme.paperWhite
            case .black: PeekTheme.paperBlack
            }
            let ink = frame == .black ? PeekTheme.paperWhite : PeekTheme.paperInk
            let mark = frame == .black ? PeekTheme.paperWhite : PeekTheme.paperWordmark
            return Style(
                paper: UIColor(paper),
                ink: UIColor(ink),
                wordmark: UIImage(named: "peek-wordmark")?.withTintColor(UIColor(mark), renderingMode: .alwaysOriginal),
                poseLine: UIColor(PeekTheme.cyan),
                shotLine: UIColor(frame == .black ? PeekTheme.paperWhite : PeekTheme.paperBlack),
                pill: UIColor(PeekTheme.paperWhite),
                pillInk: UIColor(PeekTheme.paperInk),
                tag: UIColor(PeekTheme.red),
                crown: UIImage(systemName: "crown.fill")?.withTintColor(UIColor(PeekTheme.onRed), renderingMode: .alwaysOriginal),
                bestCopy: String(localized: .bestCopy)
            )
        }
    }

    @MainActor static func render(
        _ shots: [UIImage],
        layout: PeekCore.Layout = .verticalStrip,
        frame: FrameColor = .cream,
        date: Date = .now,
        stamp: String? = nil,
        poses: [DuetPose] = [],
        scores: Bool = false
    ) -> UIImage {
        draw(shots, poses: poses, layout: layout, date: date, style: .paper(frame), stamp: stamp, scores: scores)
    }

    /// Draws the picture off the main actor, so the decode of the full-size shots does not stop the interface.
    /// - Parameter stamp: the match score in words, for the center of the footer. Nil gives a footer with no stamp.
    /// - Parameter poses: the pose of each shot, in the same order. Only the duet prints use them.
    /// - Parameter scores: true puts the score of each shot on a duet print, and marks the best copy.
    @concurrent static func renderInBackground(
        _ shots: [UIImage],
        layout: PeekCore.Layout,
        date: Date = .now,
        style: Style,
        stamp: String? = nil,
        poses: [DuetPose] = [],
        scores: Bool = false
    ) async -> UIImage {
        draw(shots, poses: poses, layout: layout, date: date, style: style, stamp: stamp, scores: scores)
    }

    private static func draw(
        _ shots: [UIImage],
        poses: [DuetPose],
        layout: PeekCore.Layout,
        date: Date,
        style: Style,
        stamp: String?,
        scores: Bool
    ) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let size = size(shotCount: shots.count, layout: layout)
        let columns = columns(shotCount: shots.count, layout: layout)
        let cell = cellSize(for: layout)
        func frame(column: Int, row: Int) -> CGRect {
            CGRect(
                origin: CGPoint(x: margin + CGFloat(column) * (cell.width + margin), y: margin + CGFloat(row) * (cell.height + margin)),
                size: cell
            )
        }
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            style.paper.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let best = scores && layout == .duetRow ? bestIndex(poses.map(\.percent)) : nil
            for (index, shot) in shots.enumerated() {
                if layout.showsPoses {
                    // The pose in the top row, the shot of that pose under it.
                    let shotFrame = frame(column: index, row: 1)
                    if index < poses.count {
                        draw(poses[index], in: frame(column: index, row: 0), style: style, context: context.cgContext)
                    }
                    draw(shot, filling: shotFrame, in: context.cgContext)
                    drawShotLine(around: shotFrame, style: style, in: context.cgContext)
                    if scores, index < poses.count, let percent = poses[index].percent {
                        drawScore(percent, on: shotFrame, style: style)
                    }
                    if index == best {
                        drawBestCopy(on: shotFrame, style: style)
                    }
                } else {
                    let shotFrame = frame(column: index % columns, row: index / columns)
                    draw(shot, filling: shotFrame, in: context.cgContext)
                    drawShotLine(around: shotFrame, style: style, in: context.cgContext)
                }
            }
            drawFooter(
                date: date,
                style: style,
                stamp: stamp,
                in: CGRect(
                    x: margin,
                    y: size.height - footerHeight(for: layout),
                    width: size.width - 2 * margin,
                    height: footerHeight(for: layout)
                )
            )
        }
    }

    /// Draws a pose whole: the picture fits in the frame, centered, with a cyan line around it.
    /// A pose with no picture gets a tint of the ink and its name.
    private static func draw(_ pose: DuetPose, in frame: CGRect, style: Style, context: CGContext) {
        guard let picture = pose.picture, picture.size.width > 0, picture.size.height > 0 else {
            style.ink.withAlphaComponent(0.08).setFill()
            context.fill(frame)
            let name = NSAttributedString(
                string: pose.name,
                attributes: [.font: UIFont.systemFont(ofSize: frame.width / 9, weight: .bold), .foregroundColor: style.ink]
            )
            let bounds = name.boundingRect(
                with: CGSize(width: frame.width * 0.8, height: frame.height),
                options: [.usesLineFragmentOrigin],
                context: nil
            )
            name.draw(with: CGRect(
                x: frame.midX - bounds.width / 2,
                y: frame.midY - bounds.height / 2,
                width: bounds.width,
                height: bounds.height
            ), options: [.usesLineFragmentOrigin], context: nil)
            return
        }
        let scale = min(frame.width / picture.size.width, frame.height / picture.size.height)
        let drawn = CGRect(
            x: frame.midX - picture.size.width * scale / 2,
            y: frame.midY - picture.size.height * scale / 2,
            width: picture.size.width * scale,
            height: picture.size.height * scale
        )
        picture.draw(in: drawn)
        context.saveGState()
        context.setStrokeColor(style.poseLine.cgColor)
        context.setLineWidth(poseBorder)
        context.stroke(drawn.insetBy(dx: poseBorder / 2, dy: poseBorder / 2))
        context.restoreGState()
    }

    /// Draws the score of a shot in a white pill at the bottom right of the shot. The sizes are design values.
    private static func drawScore(_ percent: Int, on frame: CGRect, style: Style) {
        let size = frame.width * 0.085
        let words = NSAttributedString(
            string: (Double(percent) / 100).formatted(.percent),
            attributes: [.font: UIFont.systemFont(ofSize: size, weight: .heavy), .foregroundColor: style.pillInk]
        )
        let text = words.size()
        let pill = CGRect(
            x: frame.maxX - frame.width * 0.05 - text.width - size,
            y: frame.maxY - frame.width * 0.05 - text.height - size * 0.5,
            width: text.width + size,
            height: text.height + size * 0.5
        )
        style.pill.setFill()
        UIBezierPath(roundedRect: pill, cornerRadius: pill.height / 2).fill()
        words.draw(at: CGPoint(x: pill.minX + size / 2, y: pill.minY + size * 0.25))
    }

    /// Draws the red tag with a crown at the top left of the best copy. The sizes are design values.
    private static func drawBestCopy(on frame: CGRect, style: Style) {
        let size = frame.width * 0.06
        let words = NSAttributedString(
            string: style.bestCopy,
            attributes: [.font: UIFont.systemFont(ofSize: size, weight: .bold), .foregroundColor: UIColor.white]
        )
        let text = words.size()
        let crownWidth = style.crown.map { size * $0.size.width / max($0.size.height, 1) } ?? 0
        let gap = crownWidth > 0 ? size * 0.35 : 0
        let tag = CGRect(
            x: frame.minX + frame.width * 0.05,
            y: frame.minY + frame.width * 0.05,
            width: crownWidth + gap + text.width + size,
            height: text.height + size * 0.5
        )
        style.tag.setFill()
        UIBezierPath(roundedRect: tag, cornerRadius: tag.height / 2).fill()
        style.crown?.draw(in: CGRect(x: tag.minX + size / 2, y: tag.midY - size / 2, width: crownWidth, height: size))
        words.draw(at: CGPoint(x: tag.minX + size / 2 + crownWidth + gap, y: tag.minY + size * 0.25))
    }

    /// Draws the line of the paper around a shot, inside the edge of the shot.
    private static func drawShotLine(around frame: CGRect, style: Style, in context: CGContext) {
        context.saveGState()
        context.setStrokeColor(style.shotLine.cgColor)
        context.setLineWidth(shotBorder)
        context.stroke(frame.insetBy(dx: shotBorder / 2, dy: shotBorder / 2))
        context.restoreGState()
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

    private static func drawFooter(date: Date, style: Style, stamp: String?, in frame: CGRect) {
        let ink = style.ink
        let dateFont = UIFont.systemFont(ofSize: frame.height / 6, weight: .semibold)
        let day = NSAttributedString(
            string: date.formatted(date: .abbreviated, time: .omitted),
            attributes: [.font: dateFont, .foregroundColor: ink]
        )
        // The PEEK wordmark, one third of the footer height.
        var markWidth: CGFloat = 0
        if let wordmark = style.wordmark, wordmark.size.height > 0 {
            let height = frame.height / 3
            markWidth = height * wordmark.size.width / wordmark.size.height
            wordmark.draw(in: CGRect(x: frame.minX, y: frame.midY - height / 2, width: markWidth, height: height))
        }
        day.draw(at: CGPoint(x: frame.maxX - day.size().width, y: frame.midY - day.size().height / 2))
        // The match score, in the center of the footer. Its size is a design value. A long stamp, as a score
        // with its verdict, gets smaller until it fits between the wordmark and the date.
        if let stamp {
            let gap = frame.height / 6
            let room = frame.width - 2 * (max(markWidth, day.size().width) + gap)
            var size = frame.height / 4
            var words = NSAttributedString(
                string: stamp,
                attributes: [.font: UIFont.systemFont(ofSize: size, weight: .bold), .foregroundColor: ink]
            )
            if room > 0, words.size().width > room {
                size *= room / words.size().width
                words = NSAttributedString(
                    string: stamp,
                    attributes: [.font: UIFont.systemFont(ofSize: size, weight: .bold), .foregroundColor: ink]
                )
            }
            words.draw(at: CGPoint(x: frame.midX - words.size().width / 2, y: frame.midY - words.size().height / 2))
        }
    }
}
