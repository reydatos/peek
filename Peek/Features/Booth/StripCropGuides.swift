import SwiftUI

/// Two thin lines on the viewfinder of a tall display. They show the band of an upright shot that the finished
/// picture keeps: each shot is cut to the shape of one cell of the strip, in the center.
struct StripCropGuides: View {
    var body: some View {
        GeometryReader { proxy in
            let band = StripPlacement.stripBand(in: proxy.size)
            Path { path in
                for y in [band.minY, band.maxY] {
                    path.move(to: CGPoint(x: band.minX, y: y))
                    path.addLine(to: CGPoint(x: band.maxX, y: y))
                }
            }
            .stroke(PeekTheme.paperWhite, lineWidth: 1)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
