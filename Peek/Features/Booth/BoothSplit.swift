import SwiftUI

/// Where the booth divides into a picture pane and a controls pane.
///
/// On an open iPhone Duo the division is the fold. On other wide displays it is the center.
/// A tall display has no split.
struct BoothSplit {
    /// The width of the picture pane.
    let leading: CGFloat
    /// The width of the fold between the panes.
    let gap: CGFloat

    init?(proxy: GeometryProxy) {
        let size = proxy.size
        if #available(iOS 27.1, *),
           let fold = proxy.reservedRegions(kind: .division).map(\.frame).first(where: { $0.height > $0.width }),
           fold.minX > 0, fold.maxX < size.width
        {
            leading = fold.minX
            gap = fold.width
            return
        }
        guard size.width > size.height else { return nil }
        leading = size.width / 2
        gap = 0
    }
}
