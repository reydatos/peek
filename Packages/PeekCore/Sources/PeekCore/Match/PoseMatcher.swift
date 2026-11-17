import Foundation

/// Compares the body shape of the people in the live picture with the body shape in the pose reference.
///
/// It compares the direction of each limb. It does not compare faces, expressions, or the place of a person in
/// the picture. People who copy a reference often copy it as a mirror does, so a mirrored pose is also a match.
public enum PoseMatcher {
    /// The parts of a body that the match compares, each from one joint to the next.
    static let limbs: [(PoseJoint, PoseJoint)] = [
        (.neck, .root),
        (.leftShoulder, .rightShoulder),
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee), (.rightKnee, .rightAnkle),
    ]

    /// The smallest number of limbs that two bodies must share for a comparison. This is a design value.
    public static let minimumLimbs = 4

    /// The match from 0 (different) to 1 (the same pose). Nil when there is nothing to compare:
    /// no person in the reference, or no person in the live picture with enough limbs in view.
    public static func score(reference: PoseSignature, live: PoseSignature) -> Double? {
        let direct = score(bodies: reference.bodies, live: live.bodies)
        let mirror = score(bodies: reference.bodies, live: live.mirrored.bodies)
        return [direct, mirror].compactMap(\.self).max()
    }

    /// Each person of the reference takes the live person that matches best. A person of the reference with no
    /// live person counts as 0, so a group pose needs the full group.
    private static func score(bodies reference: [PoseSignature.Body], live: [PoseSignature.Body]) -> Double? {
        guard !reference.isEmpty else { return nil }
        var remaining = live
        var total = 0.0
        var compared = 0
        for body in reference {
            let scores = remaining.map { score(body: body, live: $0) }
            guard let best = scores.enumerated().compactMap({ index, score in score.map { (index, $0) } }).max(by: { $0.1 < $1.1 })
            else { continue }
            total += best.1
            compared += 1
            remaining.remove(at: best.0)
        }
        return compared == 0 ? nil : total / Double(reference.count)
    }

    /// The mean match of the limbs that the two bodies share.
    static func score(body reference: PoseSignature.Body, live: PoseSignature.Body) -> Double? {
        let scores = limbs.compactMap { limb -> Double? in
            guard let a = angle(of: limb, in: reference), let b = angle(of: limb, in: live) else { return nil }
            var difference = abs(a - b).truncatingRemainder(dividingBy: 2 * .pi)
            if difference > .pi {
                difference = 2 * .pi - difference
            }
            // A limb in the same direction scores 1. A limb at a right angle, or more, scores 0.
            return max(0, 1 - difference / (.pi / 2))
        }
        guard scores.count >= minimumLimbs else { return nil }
        return scores.reduce(0, +) / Double(scores.count)
    }

    private static func angle(of limb: (PoseJoint, PoseJoint), in body: PoseSignature.Body) -> Double? {
        guard let from = body.joints[limb.0], let to = body.joints[limb.1], from != to else { return nil }
        return atan2(to.y - from.y, to.x - from.x)
    }
}
