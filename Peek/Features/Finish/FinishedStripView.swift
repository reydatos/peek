import SwiftUI

/// Shows the finished strip as large as possible, clear of the camera housing.
struct FinishedStripView: View {
    let strip: UIImage

    var body: some View {
        GeometryReader { proxy in
            let frame = StripPlacement.frame(
                in: proxy.size,
                avoiding: occlusions(proxy),
                aspect: strip.size.width / max(strip.size.height, 1)
            )
            Image(uiImage: strip)
                .resizable()
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
                .accessibilityLabel(Text(.finishedStrip))
        }
    }

    private func occlusions(_ proxy: GeometryProxy) -> [CGRect] {
        if #available(iOS 27.1, *) {
            proxy.reservedRegions(kind: .occlusion).map(\.frame)
        } else {
            []
        }
    }
}
