import Foundation

nonisolated struct CapturedPhoto: Sendable {
    let data: Data
    /// Degrees applied at capture to keep the photo level with the horizon.
    let rotationAngle: Double
}
