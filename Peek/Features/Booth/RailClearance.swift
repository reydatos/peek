import CoreGraphics

/// Finds the space that the side rail leaves at its top for an occluded area, such as the camera housing.
nonisolated enum RailClearance {
    /// The distance from the top of the rail to the bottom of the occluded areas that touch its top edge.
    /// An occluded area lower on the rail, or outside the rail, gives no space: the rail cannot go around it.
    static func top(railSize: CGSize, occlusions: [CGRect]) -> CGFloat {
        let bounds = CGRect(origin: .zero, size: railSize)
        return occlusions
            .map { $0.intersection(bounds) }
            .filter { !$0.isNull && !$0.isEmpty && $0.minY <= 0 }
            .map(\.maxY)
            .max() ?? 0
    }
}
