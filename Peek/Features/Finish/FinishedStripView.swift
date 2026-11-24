import SwiftUI

/// Shows the finished strip as large as possible, clear of the camera housing.
struct FinishedStripView: View {
    let strip: UIImage
    /// True on the outer display: the strip is in the column at the far right that the people in the photo can see,
    /// away from the hinge cover. A wide print, as the 2x2 or the Duet print, gets smaller to stay in that column.
    var isRightAligned = false

    var body: some View {
        GeometryReader { proxy in
            let aspect = strip.size.width / max(strip.size.height, 1)
            let frame = isRightAligned
                ? Self.outerFrame(in: proxy.size, avoiding: proxy.occlusions, aspect: aspect)
                : StripPlacement.frame(in: proxy.size, avoiding: proxy.occlusions, aspect: aspect)
            Image(uiImage: strip)
                .resizable()
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
                .accessibilityLabel(Text(.finishedStrip))
        }
    }

    /// The frame of a print in the visible column of the outer display, at the right of that column.
    static func outerFrame(in container: CGSize, avoiding occlusions: [CGRect], aspect: CGFloat) -> CGRect {
        let column = StripPlacement.outerColumn(in: container, avoiding: occlusions)
        return StripPlacement.frame(in: column.size, avoiding: [], aspect: aspect, isRightAligned: true)
            .offsetBy(dx: column.minX, dy: column.minY)
    }
}
