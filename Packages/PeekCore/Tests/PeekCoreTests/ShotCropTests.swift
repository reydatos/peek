import CoreGraphics
@testable import PeekCore
import Testing

struct ShotCropTests {
    let portrait = CGSize(width: 3000, height: 4000)
    /// The strip and 2x2 cell: 4:3.
    let cell: CGFloat = 1104.0 / 828.0

    @Test func noPersonKeepsTheUpperPartNotTheMiddle() {
        let crop = ShotCrop.rect(imageSize: portrait, cellAspect: cell, focus: nil)
        let spare = portrait.height - crop.height

        #expect(crop.width == portrait.width)
        #expect(abs(crop.height - 2250) < 0.5)
        #expect(abs(crop.minY - spare * 0.25) < 0.5)
    }

    @Test func theEyesSitInTheUpperThird() {
        // Eyes halfway down the shot, the head top a little above them.
        let focus = ShotFocus(eyeY: 0.5, headTopY: 0.45, centerX: 0.5)
        let crop = ShotCrop.rect(imageSize: portrait, cellAspect: cell, focus: focus)

        #expect(abs((2000 - crop.minY) / crop.height - 1.0 / 3) < 0.001)
    }

    @Test func theTopOfTheHeadStaysInTheCrop() {
        // A big close-up head: the eye rule alone would cut the top of the head.
        let focus = ShotFocus(eyeY: 0.4, headTopY: 0.05, centerX: 0.5)
        let crop = ShotCrop.rect(imageSize: portrait, cellAspect: cell, focus: focus)

        #expect(crop.minY <= 0.05 * 4000)
    }

    @Test func theCropStaysInsideTheShot() {
        let low = ShotCrop.rect(imageSize: portrait, cellAspect: cell, focus: ShotFocus(eyeY: 0.98, headTopY: 0.95, centerX: 0.5))
        let high = ShotCrop.rect(imageSize: portrait, cellAspect: cell, focus: ShotFocus(eyeY: 0.01, headTopY: 0, centerX: 0.5))

        #expect(abs(low.maxY - portrait.height) < 0.5)
        #expect(high.minY == 0)
    }

    @Test func aWideShotCentersTheHeadsAcross() {
        let wide = CGSize(width: 4000, height: 3000)
        let tall: CGFloat = 3.0 / 4.0
        let left = ShotCrop.rect(imageSize: wide, cellAspect: tall, focus: ShotFocus(eyeY: 0.3, headTopY: 0.2, centerX: 0.2))
        let none = ShotCrop.rect(imageSize: wide, cellAspect: tall, focus: nil)

        #expect(left.minX == 0)
        #expect(left.height == wide.height)
        #expect(abs(none.midX - wide.width / 2) < 0.5)
    }

    @Test func aShotOfTheCellShapeIsKeptWhole() {
        let crop = ShotCrop.rect(imageSize: CGSize(width: 1104, height: 828), cellAspect: cell, focus: nil)
        #expect(crop == CGRect(x: 0, y: 0, width: 1104, height: 828))
    }

    // MARK: Where the heads are

    @Test func theEyesAndTheNeckPlaceTheHead() throws {
        // Vision points: y is 1 at the top. A square picture, so x needs no change.
        let body = PoseSignature.Body(joints: [
            .neck: PosePoint(x: 0.5, y: 0.6),
            .leftEye: PosePoint(x: 0.48, y: 0.8), .rightEye: PosePoint(x: 0.52, y: 0.8),
        ])
        let focus = try #require(PoseSignature(bodies: [body]).focus(aspect: 1))

        #expect(abs(focus.eyeY - 0.2) < 0.0001)
        #expect(abs(focus.headTopY - 0.1) < 0.0001)
        #expect(abs(focus.centerX - 0.5) < 0.0001)
    }

    @Test func aPersonSeenFromTheBackUsesTheShoulders() throws {
        let body = PoseSignature.Body(joints: [
            .neck: PosePoint(x: 0.5, y: 0.6),
            .leftShoulder: PosePoint(x: 0.4, y: 0.6), .rightShoulder: PosePoint(x: 0.6, y: 0.6),
        ])
        let focus = try #require(PoseSignature(bodies: [body]).focus(aspect: 1))

        #expect(abs(focus.eyeY - (1 - 0.69)) < 0.0001)
        #expect(abs(focus.headTopY - (1 - 0.74)) < 0.0001)
    }

    @Test func aGroupKeepsTheHighestHeadAndCentersAcross() throws {
        let left = PoseSignature.Body(joints: [.neck: PosePoint(x: 0.2, y: 0.5), .nose: PosePoint(x: 0.2, y: 0.7)])
        let right = PoseSignature.Body(joints: [.neck: PosePoint(x: 0.8, y: 0.6), .nose: PosePoint(x: 0.8, y: 0.8)])
        let focus = try #require(PoseSignature(bodies: [left, right]).focus(aspect: 1))

        #expect(abs(focus.centerX - 0.5) < 0.0001)
        #expect(abs(focus.headTopY - (1 - 0.9)) < 0.0001)
    }

    @Test func xIsGivenBackAsAFractionOfTheWidth() throws {
        // A 3:4 picture: Vision x of 0.5 is 0.375 in units of the height.
        let body = PoseSignature.Body(joints: [.neck: PosePoint(x: 0.375, y: 0.5), .nose: PosePoint(x: 0.375, y: 0.7)])
        let focus = try #require(PoseSignature(bodies: [body]).focus(aspect: 0.75))

        #expect(abs(focus.centerX - 0.5) < 0.0001)
    }

    @Test func noNeckMeansNoFocus() {
        #expect(PoseSignature(bodies: [PoseSignature.Body(joints: [.nose: PosePoint(x: 0.5, y: 0.5)])]).focus(aspect: 1) == nil)
        #expect(PoseSignature(bodies: []).focus(aspect: 1) == nil)
    }

    @Test func theHeadPointsAreMirroredAndTheMatchIgnoresThem() {
        let base: [PoseJoint: PosePoint] = [
            .neck: PosePoint(x: 0, y: 0.72), .root: PosePoint(x: 0, y: 0.4),
            .leftShoulder: PosePoint(x: -0.1, y: 0.7), .rightShoulder: PosePoint(x: 0.1, y: 0.7),
            .leftElbow: PosePoint(x: -0.1, y: 0.55), .rightElbow: PosePoint(x: 0.1, y: 0.55),
        ]
        var withHead = base
        withHead[.leftEye] = PosePoint(x: -0.02, y: 0.85)
        let plain = PoseSignature(bodies: [PoseSignature.Body(joints: base)])
        let headed = PoseSignature(bodies: [PoseSignature.Body(joints: withHead)])

        #expect(PoseJoint.leftEye.mirrored == .rightEye)
        #expect(PoseMatcher.score(reference: plain, live: headed) == PoseMatcher.score(reference: plain, live: plain))
    }
}
