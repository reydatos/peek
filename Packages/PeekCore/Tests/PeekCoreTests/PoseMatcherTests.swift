import Foundation
@testable import PeekCore
import Testing

struct PoseMatcherTests {
    /// A person who stands, at the place `x`. `leftArm` and `rightArm` are the angles of the full arm, in degrees:
    /// -90 is down, 90 is up, 0 points to +x.
    private func body(x: Double = 0, leftArm: Double = -90, rightArm: Double = -90, legs: Bool = true) -> PoseSignature.Body {
        func arm(from shoulder: PosePoint, degrees: Double) -> (PosePoint, PosePoint) {
            let radians = degrees * .pi / 180
            let elbow = PosePoint(x: shoulder.x + 0.15 * cos(radians), y: shoulder.y + 0.15 * sin(radians))
            let wrist = PosePoint(x: shoulder.x + 0.3 * cos(radians), y: shoulder.y + 0.3 * sin(radians))
            return (elbow, wrist)
        }
        let leftShoulder = PosePoint(x: x - 0.1, y: 0.7)
        let rightShoulder = PosePoint(x: x + 0.1, y: 0.7)
        let left = arm(from: leftShoulder, degrees: leftArm)
        let right = arm(from: rightShoulder, degrees: rightArm)
        var joints: [PoseJoint: PosePoint] = [
            .neck: PosePoint(x: x, y: 0.72), .root: PosePoint(x: x, y: 0.4),
            .leftShoulder: leftShoulder, .rightShoulder: rightShoulder,
            .leftElbow: left.0, .leftWrist: left.1, .rightElbow: right.0, .rightWrist: right.1,
        ]
        if legs {
            joints[.leftHip] = PosePoint(x: x - 0.07, y: 0.4)
            joints[.rightHip] = PosePoint(x: x + 0.07, y: 0.4)
            joints[.leftKnee] = PosePoint(x: x - 0.07, y: 0.2)
            joints[.rightKnee] = PosePoint(x: x + 0.07, y: 0.2)
            joints[.leftAnkle] = PosePoint(x: x - 0.07, y: 0)
            joints[.rightAnkle] = PosePoint(x: x + 0.07, y: 0)
        }
        return PoseSignature.Body(joints: joints)
    }

    private func signature(_ bodies: PoseSignature.Body...) -> PoseSignature {
        PoseSignature(bodies: bodies)
    }

    @Test func theSamePoseScoresOne() throws {
        let pose = signature(body(leftArm: 90, rightArm: 0))
        let score = try #require(PoseMatcher.score(reference: pose, live: pose))
        #expect(abs(score - 1) < 0.0001)
    }

    @Test func thePlaceAndTheSizeOfThePersonDoNotChangeTheScore() throws {
        let reference = signature(body(leftArm: 90))
        var moved = body(x: 0.4, leftArm: 90)
        moved.joints = moved.joints.mapValues { PosePoint(x: $0.x * 0.5, y: $0.y * 0.5) }
        let score = try #require(PoseMatcher.score(reference: reference, live: signature(moved)))
        #expect(abs(score - 1) < 0.0001)
    }

    @Test func aMirroredPoseIsAMatch() throws {
        // The reference has the left arm up. The live person has the right arm up, as a mirror shows it.
        let score = try #require(PoseMatcher.score(
            reference: signature(body(leftArm: 90, rightArm: -90)),
            live: signature(body(leftArm: -90, rightArm: 90))
        ))
        #expect(abs(score - 1) < 0.0001)
    }

    @Test func aDifferentPoseScoresLower() throws {
        let reference = signature(body(leftArm: 90, rightArm: 90))
        let armsDown = try #require(PoseMatcher.score(reference: reference, live: signature(body())))
        let armsNearlyUp = try #require(PoseMatcher.score(reference: reference, live: signature(body(leftArm: 70, rightArm: 110))))
        #expect(armsDown < armsNearlyUp)
        #expect(armsNearlyUp < 1)
        // Four of the ten limbs are opposite, and the other six are the same.
        #expect(abs(armsDown - 0.6) < 0.0001)
    }

    @Test func aGroupPoseNeedsTheFullGroup() throws {
        let reference = signature(body(x: -0.3, leftArm: 90), body(x: 0.3, rightArm: 90))
        let two = try #require(PoseMatcher.score(reference: reference, live: signature(body(x: 0.2, rightArm: 90), body(x: -0.2, leftArm: 90))))
        let one = try #require(PoseMatcher.score(reference: reference, live: signature(body(leftArm: 90))))
        #expect(abs(two - 1) < 0.0001)
        #expect(abs(one - 0.5) < 0.0001)
    }

    @Test func aPersonInTheBackgroundDoesNotLowerTheScore() throws {
        let reference = signature(body(leftArm: 90))
        let score = try #require(PoseMatcher.score(reference: reference, live: signature(body(x: 0.5), body(leftArm: 90))))
        #expect(abs(score - 1) < 0.0001)
    }

    @Test func aJointThatIsNotInViewIsIgnored() throws {
        // The legs of the live person are out of the picture.
        let score = try #require(PoseMatcher.score(reference: signature(body(leftArm: 90)), live: signature(body(leftArm: 90, legs: false))))
        #expect(abs(score - 1) < 0.0001)
    }

    @Test func thereIsNoScoreWithNoPersonOrTooFewLimbs() {
        let reference = signature(body())
        #expect(PoseMatcher.score(reference: reference, live: PoseSignature(bodies: [])) == nil)
        #expect(PoseMatcher.score(reference: PoseSignature(bodies: []), live: reference) == nil)
        let head = PoseSignature.Body(joints: [.neck: PosePoint(x: 0, y: 0.7), .leftShoulder: PosePoint(x: -0.1, y: 0.7)])
        #expect(PoseMatcher.score(reference: reference, live: signature(head)) == nil)
    }

    @Test func aSignatureKeepsItsJointsInStorage() throws {
        let pose = signature(body(leftArm: 45))
        let decoded = try JSONDecoder().decode(PoseSignature.self, from: JSONEncoder().encode(pose))
        #expect(decoded == pose)
    }
}

struct MatchHoldTests {
    /// Gives the scores to the rule, each with its time, and returns the answer for each score.
    private func answers(_ hold: inout MatchHold, _ scores: [(Double?, TimeInterval)]) -> [Bool] {
        scores.map { hold.update(score: $0.0, at: $0.1) }
    }

    @Test func theMatchMustHoldForTheFullTime() {
        var hold = MatchHold(limit: 0.8, duration: 1)
        #expect(answers(&hold, [(0.9, 0), (0.85, 0.5), (0.8, 1)]) == [false, false, true])
    }

    @Test func aLowScoreOrNoScoreStartsTheWaitAgain() {
        var hold = MatchHold(limit: 0.8, duration: 1)
        let result = answers(&hold, [(0.9, 0), (0.5, 0.5), (0.9, 1), (nil, 1.5), (0.9, 2), (0.9, 3)])
        #expect(result == [false, false, false, false, false, true])
    }

    @Test func aResetStartsTheWaitAgain() {
        var hold = MatchHold(limit: 0.8, duration: 1)
        let first = answers(&hold, [(0.9, 0)])
        hold.reset()
        let next = answers(&hold, [(0.9, 1), (0.9, 2)])
        #expect(first == [false])
        #expect(next == [false, true])
    }
}
