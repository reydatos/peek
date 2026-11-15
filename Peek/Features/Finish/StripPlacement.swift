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

    /// The frame of a picture that covers the full container, with its right edge at the right edge of the container.
    /// The picture keeps its aspect (width / height). The part that does not fit is outside the container:
    /// at the left, or in equal parts at the top and the bottom.
    ///
    /// The outer display uses this (owner decision, 2026-11-14): the picture covers the whole screen, and the part
    /// under the hinge cover at the left is the part that the people in the photo can lose.
    static func rightPinnedFill(in container: CGSize, aspect: CGFloat) -> CGRect {
        let width = max(container.width, container.height * aspect)
        let height = width / aspect
        return CGRect(x: container.width - width, y: (container.height - height) / 2, width: width, height: height)
    }

    /// The column of the outer display that the people in the photo can see: 3:4, at the full height, at the far right.
    /// The labels and the caption of the outer display go in this column.
    ///
    /// The system does not report the hinge cover of an open iPhone Duo (it reports cameras and the fold only),
    /// so the app cannot measure it. On a physical Duo, a picture in this column was in full view, and a picture
    /// with the full width of the display was covered at the left (2026-11-14).
    static func outerColumn(in container: CGSize, avoiding occlusions: [CGRect]) -> CGRect {
        frame(in: container, avoiding: occlusions, aspect: 3 / 4, isRightAligned: true)
    }

    /// The band of a picture that one cell of the strip keeps: the shape of the cell, at the full width, in the center.
    /// A picture that is wider than the cell keeps its full height.
    static func stripBand(in picture: CGSize) -> CGRect {
        let height = min(picture.height, picture.width / StripRenderer.cellAspect)
        return CGRect(x: 0, y: (picture.height - height) / 2, width: picture.width, height: height)
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
