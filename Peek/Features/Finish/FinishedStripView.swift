import SwiftUI

/// Shows the finished strip as large as possible, clear of the camera housing.
struct FinishedStripView: View {
    let strip: UIImage
    /// True on the outer display: the strip is at the far right, away from the hinge cover.
    var isRightAligned = false

    var body: some View {
        GeometryReader { proxy in
            let frame = StripPlacement.frame(
                in: proxy.size,
                avoiding: proxy.occlusions,
                aspect: strip.size.width / max(strip.size.height, 1),
                isRightAligned: isRightAligned
            )
            Image(uiImage: strip)
                .resizable()
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
                .accessibilityLabel(Text(.finishedStrip))
        }
    }
}
