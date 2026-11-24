import CoreGraphics
import Foundation

/// Where the heads are in a shot, so a crop keeps them. Each value is a fraction of the upright picture:
/// y from 0 at the top to 1 at the bottom, x from 0 at the left to 1 at the right.
public struct ShotFocus: Equatable, Sendable {
    /// The mean eye line of the people.
    public var eyeY: Double
    /// The highest top of a head.
    public var headTopY: Double
    /// The middle of the heads across the picture.
    public var centerX: Double

    public init(eyeY: Double, headTopY: Double, centerX: Double) {
        self.eyeY = eyeY
        self.headTopY = headTopY
        self.centerX = centerX
    }
}

extension PoseSignature {
    /// The head part of a body, from the eyes to the top of the head, for each eye-to-neck distance. A design value
    /// from the proportions of a head: the top is about half the eye-to-neck distance above the eyes.
    static let headTopAboveEyes = 0.5
    /// With no head point (a person seen from the back), the eyes and the top of the head are estimated from the
    /// shoulder width. Design values from the proportions of a body.
    static let eyesAboveNeckPerShoulder = 0.45
    static let headTopAboveNeckPerShoulder = 0.7

    /// Where the heads are, or nil when no person has a neck in the signature.
    /// - Parameter aspect: the width of the upright picture divided by its height. The signature has x in units
    ///   of the height, so the aspect gives x back as a fraction of the width.
    public func focus(aspect: Double) -> ShotFocus? {
        guard aspect > 0 else { return nil }
        var eyes: [Double] = []
        var tops: [Double] = []
        var xs: [Double] = []
        for body in bodies {
            guard let neck = body.joints[.neck] else { continue }
            // The points are as Vision gives them: y is 0 at the bottom and 1 at the top.
            let eyeLevel = [PoseJoint.leftEye, .rightEye, .leftEar, .rightEar].compactMap { body.joints[$0] }
            let level = eyeLevel.isEmpty ? body.joints[.nose].map { [$0] } ?? [] : eyeLevel
            var eye: Double
            var top: Double
            var x: Double
            if !level.isEmpty {
                eye = level.map(\.y).reduce(0, +) / Double(level.count)
                x = level.map(\.x).reduce(0, +) / Double(level.count)
                top = eye + max(0, eye - neck.y) * Self.headTopAboveEyes
            } else if let left = body.joints[.leftShoulder], let right = body.joints[.rightShoulder] {
                let width = hypot(left.x - right.x, left.y - right.y)
                eye = neck.y + width * Self.eyesAboveNeckPerShoulder
                top = neck.y + width * Self.headTopAboveNeckPerShoulder
                x = neck.x
            } else {
                continue
            }
            eyes.append(1 - eye)
            tops.append(1 - top)
            xs.append(x / aspect)
        }
        guard !eyes.isEmpty, let top = tops.min(), let left = xs.min(), let right = xs.max() else { return nil }
        return ShotFocus(eyeY: eyes.reduce(0, +) / Double(eyes.count), headTopY: top, centerX: (left + right) / 2)
    }
}

/// The part of a shot that a cell of a finished picture keeps.
public enum ShotCrop {
    /// The eye line sits this far down the crop: the upper third, as in a portrait. A design value.
    public static let eyeLine = 1.0 / 3
    /// Space above the top of the highest head, as a fraction of the crop height. A design value.
    public static let headroom = 0.04
    /// With no person found, the crop keeps the upper part of the shot: it starts this far down the part that
    /// does not fit (0 is the top, 0.5 is the middle). A design value (owner decision, 2026-11-24).
    public static let upperBias = 0.25

    /// The crop, in the coordinates of the upright shot: the shape of the cell, as large as the shot allows.
    /// - Parameters:
    ///   - imageSize: the size of the upright shot.
    ///   - cellAspect: the width of the cell divided by its height.
    ///   - focus: where the heads are, or nil with no person found.
    public static func rect(imageSize: CGSize, cellAspect: CGFloat, focus: ShotFocus?) -> CGRect {
        let width = imageSize.width, height = imageSize.height
        guard width > 0, height > 0, cellAspect > 0 else { return CGRect(origin: .zero, size: imageSize) }
        if width / height > cellAspect {
            // The shot is wider than the cell: keep the full height, and center the heads across.
            let cropWidth = height * cellAspect
            let wanted = focus.map { CGFloat($0.centerX) * width - cropWidth / 2 } ?? (width - cropWidth) / 2
            return CGRect(x: min(max(wanted, 0), width - cropWidth), y: 0, width: cropWidth, height: height)
        }
        // The shot is taller than the cell: keep the full width, and place the eyes in the upper third,
        // with the top of the heads in the crop.
        let cropHeight = width / cellAspect
        let spare = height - cropHeight
        var wanted = spare * CGFloat(upperBias)
        if let focus {
            wanted = CGFloat(focus.eyeY) * height - cropHeight * CGFloat(eyeLine)
            wanted = min(wanted, CGFloat(focus.headTopY) * height - cropHeight * CGFloat(headroom))
        }
        return CGRect(x: 0, y: min(max(wanted, 0), spare), width: width, height: cropHeight)
    }
}
