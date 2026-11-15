import CoreGraphics

/// The shape of the live picture on a display: the width divided by the height.
nonisolated enum PreviewAspect {
    /// The aspect before the camera reports its format: a 4:3 sensor that is level with a wide display.
    static let fallback: CGFloat = 4.0 / 3.0

    /// The aspect of the picture of a sensor after the rotation that keeps it level with the horizon.
    /// A quarter turn (90 or 270 degrees) exchanges the width and the height.
    static func aspect(sensorWidth: Int32, sensorHeight: Int32, rotationAngle: CGFloat) -> CGFloat {
        guard sensorWidth > 0, sensorHeight > 0 else { return fallback }
        let isQuarterTurn = Int(rotationAngle.rounded()) % 180 != 0
        let width = CGFloat(isQuarterTurn ? sensorHeight : sensorWidth)
        let height = CGFloat(isQuarterTurn ? sensorWidth : sensorHeight)
        return width / height
    }
}
