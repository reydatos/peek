import CoreMedia
import ImageIO
import PeekCore
import UIKit
import Vision

/// Finds the body shape of the people in a picture, on the device, with the Vision framework.
/// No picture leaves the phone.
nonisolated enum PoseAnalyzer {
    /// A joint below this confidence is not in the signature. This is a design value.
    static let minimumConfidence: Float = 0.3

    private static let joints: [HumanBodyPoseObservation.JointName: PoseJoint] = [
        .neck: .neck, .root: .root,
        .leftShoulder: .leftShoulder, .rightShoulder: .rightShoulder,
        .leftElbow: .leftElbow, .rightElbow: .rightElbow,
        .leftWrist: .leftWrist, .rightWrist: .rightWrist,
        .leftHip: .leftHip, .rightHip: .rightHip,
        .leftKnee: .leftKnee, .rightKnee: .rightKnee,
        .leftAnkle: .leftAnkle, .rightAnkle: .rightAnkle,
        // The head points place the head when the app crops a shot. The match does not compare them.
        .nose: .nose, .leftEye: .leftEye, .rightEye: .rightEye, .leftEar: .leftEar, .rightEar: .rightEar,
    ]

    /// The orientation that makes a frame upright.
    /// - Parameter rotationAngle: the clockwise angle, in degrees, that makes the frame upright.
    static func orientation(rotationAngle: CGFloat) -> CGImagePropertyOrientation {
        switch (Int(rotationAngle.rounded()) % 360 + 360) % 360 {
        case 90: .right
        case 180: .down
        case 270: .left
        default: .up
        }
    }

    /// The body shape in a picture. Nil when the picture can not be read. A picture with no person has no body.
    static func signature(of image: UIImage) async -> PoseSignature? {
        guard let cgImage = image.cgImage else { return nil }
        let orientation = orientation(of: image.imageOrientation)
        let isTurned = [.left, .right, .leftMirrored, .rightMirrored].contains(orientation)
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        let observations = try? await DetectHumanBodyPoseRequest().perform(on: cgImage, orientation: orientation)
        return observations.map { signature(of: $0, uprightSize: isTurned ? CGSize(width: size.height, height: size.width) : size) }
    }

    /// The body shape in a live frame.
    static func signature(in frame: CMSampleBuffer, orientation: CGImagePropertyOrientation) async -> PoseSignature? {
        guard let buffer = CMSampleBufferGetImageBuffer(frame) else { return nil }
        let size = CGSize(width: CVPixelBufferGetWidth(buffer), height: CVPixelBufferGetHeight(buffer))
        let isTurned = orientation == .left || orientation == .right
        nonisolated(unsafe) let pixels = buffer
        let observations = try? await DetectHumanBodyPoseRequest().perform(on: pixels, orientation: orientation)
        return observations.map { signature(of: $0, uprightSize: isTurned ? CGSize(width: size.height, height: size.width) : size) }
    }

    /// Vision gives each point from 0 to 1 on each axis. The signature needs the same unit on the two axes,
    /// so x gets the width of the picture in units of its height.
    private static func signature(of observations: [HumanBodyPoseObservation], uprightSize: CGSize) -> PoseSignature {
        let aspect = uprightSize.height > 0 ? uprightSize.width / uprightSize.height : 1
        return PoseSignature(bodies: observations.map { observation in
            var body: [PoseJoint: PosePoint] = [:]
            for (name, joint) in observation.allJoints() where joint.confidence >= minimumConfidence {
                if let key = joints[name] {
                    body[key] = PosePoint(x: joint.location.x * aspect, y: joint.location.y)
                }
            }
            return PoseSignature.Body(joints: body)
        })
    }

    private static func orientation(of orientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch orientation {
        case .up: .up
        case .down: .down
        case .left: .left
        case .right: .right
        case .upMirrored: .upMirrored
        case .downMirrored: .downMirrored
        case .leftMirrored: .leftMirrored
        case .rightMirrored: .rightMirrored
        @unknown default: .up
        }
    }
}
