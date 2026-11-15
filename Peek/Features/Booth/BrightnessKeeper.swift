import CoreGraphics

/// Decides the brightness of the display for the glam light. It keeps the brightness from before the light,
/// and gives it back when the light stops.
nonisolated struct BrightnessKeeper {
    /// The brightness from before the light. Nil while the light is off.
    private(set) var saved: CGFloat?

    /// Returns the brightness to set, or nil for no change.
    mutating func update(isBright: Bool, current: CGFloat) -> CGFloat? {
        if isBright {
            if saved == nil {
                saved = current
            }
            return current == 1 ? nil : 1
        }
        defer { saved = nil }
        return saved
    }
}
