import CoreGraphics

/// The fill light for dark places: a display at full brightness with warm light areas, as in the Glam app.
nonisolated enum GlamLight {
    /// The display that can light the people in the photo.
    enum Surface: Equatable {
        /// The outer display shows the booth to the people, so it faces them.
        case outer
        /// The front camera is in use, so the inner display faces the people.
        case inner
        /// No display faces the people: one screen with the rear camera.
        case none
    }

    /// A display lights the people only when it is on the same side as the lens in use.
    static func surface(isOuterDisplayPresenting: Bool, isSelfie: Bool) -> Surface {
        if isSelfie {
            return .inner
        }
        return isOuterDisplayPresenting ? .outer : .none
    }

    /// Below this EXIF brightness value, the place is dark. The Glam app uses the same limit for its low-light mode.
    static let lowLightLimit = -1.0

    static func isLowLight(brightnessValue: Double) -> Bool {
        brightnessValue < lowLightLimit
    }
}
