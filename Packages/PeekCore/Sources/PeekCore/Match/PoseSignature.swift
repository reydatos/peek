import Foundation

/// A joint of a body that the pose match compares.
public enum PoseJoint: String, Codable, CaseIterable, Sendable {
    case neck, root
    case leftShoulder, rightShoulder, leftElbow, rightElbow, leftWrist, rightWrist
    case leftHip, rightHip, leftKnee, rightKnee, leftAnkle, rightAnkle

    /// The same joint on the other side of the body.
    var mirrored: PoseJoint {
        switch self {
        case .neck, .root: self
        case .leftShoulder: .rightShoulder
        case .rightShoulder: .leftShoulder
        case .leftElbow: .rightElbow
        case .rightElbow: .leftElbow
        case .leftWrist: .rightWrist
        case .rightWrist: .leftWrist
        case .leftHip: .rightHip
        case .rightHip: .leftHip
        case .leftKnee: .rightKnee
        case .rightKnee: .leftKnee
        case .leftAnkle: .rightAnkle
        case .rightAnkle: .leftAnkle
        }
    }
}

/// A point of a picture. The two axes have the same unit, so an angle between two points is a true angle.
public struct PosePoint: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// The body shape of the people in one picture: for each person, the joints that the detector found.
/// A joint that the detector did not find with confidence is not in the signature.
public struct PoseSignature: Codable, Equatable, Sendable {
    public struct Body: Codable, Equatable, Sendable {
        public var joints: [PoseJoint: PosePoint]

        public init(joints: [PoseJoint: PosePoint]) {
            self.joints = joints
        }

        /// The body as a mirror shows it: left and right change places.
        var mirrored: Body {
            Body(joints: Dictionary(uniqueKeysWithValues: joints.map { ($0.key.mirrored, PosePoint(x: -$0.value.x, y: $0.value.y)) }))
        }
    }

    public var bodies: [Body]

    public init(bodies: [Body]) {
        self.bodies = bodies
    }

    var mirrored: PoseSignature {
        PoseSignature(bodies: bodies.map(\.mirrored))
    }
}
