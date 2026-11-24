import Foundation
@testable import Peek
import PeekCore
import Testing
import UIKit

@MainActor
struct PoseMatchTests {
    /// A person who stands with the arms down, or with the arms up.
    private nonisolated static func signature(armsUp: Bool = false) -> PoseSignature {
        let wrist = armsUp ? 1.0 : 0.4
        return PoseSignature(bodies: [PoseSignature.Body(joints: [
            .neck: PosePoint(x: 0, y: 0.72), .root: PosePoint(x: 0, y: 0.4),
            .leftShoulder: PosePoint(x: -0.1, y: 0.7), .rightShoulder: PosePoint(x: 0.1, y: 0.7),
            .leftElbow: PosePoint(x: -0.1, y: (0.7 + wrist) / 2), .leftWrist: PosePoint(x: -0.1, y: wrist),
            .rightElbow: PosePoint(x: 0.1, y: (0.7 + wrist) / 2), .rightWrist: PosePoint(x: 0.1, y: wrist),
        ])])
    }

    private final class Clock {
        var time = 0.0
    }

    private let capture = FakeCapture()
    private let clock = Clock()
    private let cue = PoseCatalog().classicPack.cues[0]

    private func match(reference: PoseSignature? = signature()) -> PoseMatch {
        PoseMatch(capture: capture, analyze: { _ in reference }, now: { [clock] in clock.time })
    }

    private func ready(_ match: PoseMatch) async {
        match.update(cue: cue, phase: .ready, isCameraRunning: true, reviewImage: nil)
        await match.task?.value
    }

    @Test func theLiveScoreShowsWhileTheBoothIsReady() async {
        let match = match()
        await ready(match)
        #expect(match.canMatch)
        #expect(await capture.poseHandler != nil)

        match.receive(Self.signature())
        #expect(match.score == 1)
        match.receive(Self.signature(armsUp: true))
        #expect(MatchLevel(score: match.score) != .matched)
        match.receive(PoseSignature(bodies: []))
        #expect(match.score == nil)
    }

    @Test func theCameraStopsTheExaminationWhenTheBoothIsNotReady() async {
        let match = match()
        await ready(match)
        match.receive(Self.signature())
        match.update(cue: cue, phase: .countdown(remaining: 3), isCameraRunning: true, reviewImage: nil)
        await match.task?.value
        #expect(await capture.poseHandler == nil)
        #expect(match.score == nil)
        // A frame that was in examination gives no score now.
        match.receive(Self.signature())
        #expect(match.score == nil)
    }

    /// A chest-up person: the neck and the shoulders only, too few limbs to compare.
    private nonisolated static let chestUp = PoseSignature(bodies: [PoseSignature.Body(joints: [
        .neck: PosePoint(x: 0, y: 0.72),
        .leftShoulder: PosePoint(x: -0.1, y: 0.7), .rightShoulder: PosePoint(x: 0.1, y: 0.7),
    ])])

    /// Owner decision (2026-11-24): a person too close to compare has no score, and the meter says to step back.
    @Test func aPersonTooCloseGetsTheStepBackTipNotAScore() async {
        let match = match()
        await ready(match)

        match.receive(Self.chestUp)
        #expect(match.score == nil)
        #expect(match.isLiveTooClose)
        #expect(match.meterTooClose)

        // No person at all is not "too close".
        match.receive(PoseSignature(bodies: []))
        #expect(!match.isLiveTooClose)

        match.receive(Self.signature())
        #expect(match.score == 1)
        #expect(!match.meterTooClose)
    }

    @Test func aFinishedShotTooCloseHasNoScoreButItsBodyStaysForTheCrop() async {
        // The pose picture has a full body. The shot, a 7 x 9 picture, is chest-up.
        let match = PoseMatch(capture: capture, analyze: { image in
            image.size == CGSize(width: 7, height: 9) ? Self.chestUp : Self.signature()
        })
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let shot = UIGraphicsImageRenderer(size: CGSize(width: 7, height: 9), format: format).image { _ in }
        #expect(cue.picture != nil)

        let result = await match.finalResult(of: shot, cue: cue)

        #expect(result.score == nil)
        #expect(result.body == Self.chestUp)
        let full = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 9), format: format).image { _ in }
        #expect(await match.finalResult(of: full, cue: cue).score == 1)
    }

    @Test func aPosePictureWithNoPersonHasNoMatch() async {
        let match = match(reference: PoseSignature(bodies: []))
        await ready(match)
        #expect(!match.canMatch)
        #expect(await capture.poseHandler == nil)
    }

    @Test func theAutomaticShutterStartsAfterTheMatchHolds() async {
        let match = match()
        var starts = 0
        match.onHold = { starts += 1 }
        match.isAutoShutterOn = true
        await ready(match)

        match.receive(Self.signature())
        clock.time = PoseMatchTuning.holdSeconds / 2
        match.receive(Self.signature())
        #expect(starts == 0)
        clock.time = PoseMatchTuning.holdSeconds
        match.receive(Self.signature())
        #expect(starts == 1)
        // The wait starts again after the shot.
        match.receive(Self.signature())
        #expect(starts == 1)
    }

    @Test func theAutomaticShutterDoesNotStartWhenOffOrBlockedOrOnADifferentPose() async {
        let match = match()
        var starts = 0
        match.onHold = { starts += 1 }
        await ready(match)

        func hold(_ signature: PoseSignature) {
            match.receive(signature)
            clock.time += PoseMatchTuning.holdSeconds
            match.receive(signature)
        }
        hold(Self.signature())
        #expect(starts == 0)

        match.isAutoShutterOn = true
        match.isBlocked = true
        hold(Self.signature())
        #expect(starts == 0)

        await match.task?.value
        #expect(await capture.poseHandler == nil)

        match.isBlocked = false
        hold(Self.signature(armsUp: true))
        #expect(starts == 0)

        hold(Self.signature())
        #expect(starts == 1)
    }

    @Test func theReviewShowsTheScoreOfTheShot() async throws {
        let match = match()
        await ready(match)
        let take = Take(slotID: SlotID(0), token: CaptureToken(), assetName: "a", rotationAngle: 0)
        let image = try #require(UIImage(data: FakeCapture.photoData))
        match.update(cue: cue, phase: .review(take), isCameraRunning: true, reviewImage: image)
        await match.task?.value
        #expect(match.reviewScore == 1)
        #expect(match.score == nil)

        match.update(cue: cue, phase: .ready, isCameraRunning: true, reviewImage: nil)
        #expect(match.reviewScore == nil)
    }

    @Test func theLevelsUseTheLimits() {
        #expect(MatchLevel(score: nil) == .none)
        #expect(MatchLevel(score: PoseMatchTuning.matchLimit) == .matched)
        #expect(MatchLevel(score: PoseMatchTuning.weakLimit) == .near)
        #expect(MatchLevel(score: PoseMatchTuning.weakLimit - 0.01) == .different)
    }

    @Test func theAutomaticShutterOfTheBoothStartsAShotOnlyInReady() async {
        let model = BoothSessionModel(capture: capture, analyzePose: { _ in Self.signature() }, sleep: { _ in })
        model.countdown = .manual
        await model.startCamera()
        await model.match.task?.value
        #expect(model.state.phase == .ready)
        #expect(model.match.canMatch)

        model.match.onHold()
        await model.captureTask?.value
        guard case .review = model.state.phase else {
            Issue.record("The automatic shutter did not take the shot")
            return
        }
        // In review the same signal does nothing: the reducer accepts a start in `ready` only.
        model.match.onHold()
        guard case .review = model.state.phase else {
            Issue.record("The automatic shutter changed the review")
            return
        }
        await model.match.task?.value
        #expect(model.match.reviewScore == 1)
    }

    @Test func theOrientationOfAFrameComesFromItsRotation() {
        #expect(PoseAnalyzer.orientation(rotationAngle: 0) == .up)
        #expect(PoseAnalyzer.orientation(rotationAngle: 90) == .right)
        #expect(PoseAnalyzer.orientation(rotationAngle: 180) == .down)
        #expect(PoseAnalyzer.orientation(rotationAngle: -90) == .left)
        #expect(PoseAnalyzer.orientation(rotationAngle: 270) == .left)
    }
}
