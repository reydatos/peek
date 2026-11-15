import SwiftUI

extension GeometryProxy {
    /// The areas of the display that content must not cover, such as the camera housing.
    /// iOS 27.0 has no such areas.
    var occlusions: [CGRect] {
        if #available(iOS 27.1, *) {
            reservedRegions(kind: .occlusion).map(\.frame)
        } else {
            []
        }
    }
}
