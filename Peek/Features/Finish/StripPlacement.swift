import CoreGraphics

/// Finds where the finished strip goes on a display that has occluded areas, such as the camera housing.
enum StripPlacement {
    /// The largest frame with the aspect (width / height) that is inside the container and touches no occlusion.
    /// With no free area, the strip fits the full container.
    static func frame(in container: CGSize, avoiding occlusions: [CGRect], aspect: CGFloat) -> CGRect {
        let bounds = CGRect(origin: .zero, size: container)
        let blocked = occlusions.map { $0.intersection(bounds) }.filter { !$0.isNull && !$0.isEmpty }
        var areas = [bounds]
        for block in blocked {
            areas += [
                CGRect(x: 0, y: 0, width: block.minX, height: container.height),
                CGRect(x: block.maxX, y: 0, width: container.width - block.maxX, height: container.height),
                CGRect(x: 0, y: 0, width: container.width, height: block.minY),
                CGRect(x: 0, y: block.maxY, width: container.width, height: container.height - block.maxY),
            ]
        }
        let free = areas.filter { area in
            area.width > 0 && area.height > 0 && !blocked.contains { $0.intersects(area) }
        }
        let fitted = free.map { fit(aspect: aspect, in: $0) }
        return fitted.max { $0.width < $1.width } ?? fit(aspect: aspect, in: bounds)
    }

    private static func fit(aspect: CGFloat, in area: CGRect) -> CGRect {
        let width = min(area.width, area.height * aspect)
        let size = CGSize(width: width, height: width / aspect)
        return CGRect(
            x: area.midX - size.width / 2,
            y: area.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }
}
