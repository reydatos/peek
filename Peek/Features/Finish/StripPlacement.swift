import CoreGraphics

/// Finds where a picture goes on a display that has occluded areas, such as the camera housing or the hinge cover.
enum StripPlacement {
    /// The largest frame with the aspect (width / height) that is inside the container and touches no occlusion.
    /// With no free area, the picture fits the full container.
    ///
    /// A right-aligned frame is at the right edge of its free area. On the outer display of an open iPhone Duo,
    /// the hinge cover is at the left, so a picture at the far right stays in view.
    static func frame(
        in container: CGSize,
        avoiding occlusions: [CGRect],
        aspect: CGFloat,
        isRightAligned: Bool = false
    ) -> CGRect {
        let bounds = CGRect(origin: .zero, size: container)
        let fitted = freeAreas(in: container, avoiding: occlusions).map { fit(aspect: aspect, in: $0, isRightAligned: isRightAligned) }
        // With two frames of one size, the frame at the right is first.
        let largest = fitted.max { ($0.width, $0.maxX) < ($1.width, $1.maxX) }
        return largest ?? fit(aspect: aspect, in: bounds, isRightAligned: isRightAligned)
    }

    /// The largest area of the container that touches no occlusion. With no free area, the full container.
    static func freeArea(in container: CGSize, avoiding occlusions: [CGRect]) -> CGRect {
        let areas = freeAreas(in: container, avoiding: occlusions)
        return areas.max { ($0.width * $0.height, $0.maxX) < ($1.width * $1.height, $1.maxX) }
            ?? CGRect(origin: .zero, size: container)
    }

    private static func freeAreas(in container: CGSize, avoiding occlusions: [CGRect]) -> [CGRect] {
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
        return areas.filter { area in
            area.width > 0 && area.height > 0 && !blocked.contains { $0.intersects(area) }
        }
    }

    private static func fit(aspect: CGFloat, in area: CGRect, isRightAligned: Bool) -> CGRect {
        let width = min(area.width, area.height * aspect)
        let size = CGSize(width: width, height: width / aspect)
        return CGRect(
            x: isRightAligned ? area.maxX - size.width : area.midX - size.width / 2,
            y: area.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }
}
