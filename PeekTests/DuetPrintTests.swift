@testable import Peek
import PeekCore
import Testing
import UIKit

struct DuetPrintTests {
    /// Takes and accepts all four shots of the Classic pack in a layout.
    func completedModel(layout: PeekCore.Layout) async -> BoothSessionModel {
        let model = BoothSessionModel(capture: FakeCapture(), saver: FakeSaver(), sleep: { _ in })
        model.layout = layout
        await model.startCamera()
        for _ in model.state.slots {
            model.send(.start)
            await model.countdownTask?.value
            await model.captureTask?.value
            model.send(.accept)
        }
        await model.stripTask?.value
        return model
    }

    /// A plain picture of one color.
    func picture(_ color: UIColor, _ size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    /// The color of one pixel, as red, green, and blue from 0 to 255.
    func pixel(_ image: UIImage, _ point: CGPoint) -> (Int, Int, Int) {
        var bytes = [UInt8](repeating: 0, count: 4)
        let context = CGContext(
            data: &bytes, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.draw(image.cgImage!, in: CGRect(x: -point.x, y: point.y - image.size.height + 1, width: image.size.width, height: image.size.height))
        return (Int(bytes[0]), Int(bytes[1]), Int(bytes[2]))
    }

    @Test func duetSizesAreTheDesignSizes() {
        #expect(StripRenderer.size(shotCount: 4, layout: .duetRow) == CGSize(width: 3552, height: 2640))
        #expect(StripRenderer.size(shotCount: 1, layout: .duetSingle) == CGSize(width: 1200, height: 3280))
    }

    @Test func aFinishedSetDrawsTheDuetRow() async {
        let model = await completedModel(layout: .duetRow)

        #expect(model.strip?.size == CGSize(width: 3552, height: 2640))
    }

    @Test func aFinishedSetDrawsTheSingleDuetWithOneShot() async {
        let model = await completedModel(layout: .duetSingle)

        #expect(model.strip?.size == CGSize(width: 1200, height: 3280))
    }

    @Test func aChangeToADuetLayoutDrawsAgain() async {
        let model = await completedModel(layout: .verticalStrip)

        model.layout = .duetRow
        #expect(model.strip == nil)
        await model.stripTask?.value

        #expect(model.strip?.size == CGSize(width: 3552, height: 2640))
    }

    @Test func theSingleDuetTakesTheChosenShotElseTheBestMatch() {
        let ids = ["a", "b", "c", "d"]

        #expect(BoothSessionModel.duetIndex(chosen: 2, cueIDs: ids, percents: ["a": 90]) == 2)
        #expect(BoothSessionModel.duetIndex(chosen: nil, cueIDs: ids, percents: ["a": 40, "c": 91, "d": 70]) == 2)
        // Equal scores: the first shot wins, so the picture does not change between draws.
        #expect(BoothSessionModel.duetIndex(chosen: nil, cueIDs: ids, percents: ["b": 80, "d": 80]) == 1)
        // No score, or a choice that is not a slot: the first shot.
        #expect(BoothSessionModel.duetIndex(chosen: nil, cueIDs: ids, percents: [:]) == 0)
        #expect(BoothSessionModel.duetIndex(chosen: 9, cueIDs: ids, percents: [:]) == 0)
    }

    /// The pose is drawn whole in its 3:4 cell, with the cyan line at its edge. The shot fills the cell below.
    @Test func thePoseIsDrawnWholeAboveTheShot() {
        let pose = StripRenderer.DuetPose(picture: picture(.red, CGSize(width: 300, height: 400)), name: "Lean")
        let print = StripRenderer.render([picture(.blue, CGSize(width: 400, height: 300))], layout: .duetSingle, poses: [pose])
        let margin = StripRenderer.margin
        let cell = StripRenderer.singleCell

        let poseCenter = pixel(print, CGPoint(x: margin + cell.width / 2, y: margin + cell.height / 2))
        let poseEdge = pixel(print, CGPoint(x: margin + 2, y: margin + cell.height / 2))
        let shotCenter = pixel(print, CGPoint(x: margin + cell.width / 2, y: 2 * margin + cell.height * 1.5))

        #expect(poseCenter.0 > 200 && poseCenter.2 < 60)
        #expect(poseEdge.1 > 180 && poseEdge.2 > 180 && poseEdge.0 < 80)
        #expect(shotCenter.2 > 200 && shotCenter.0 < 60)
    }

    /// A pose with no picture gets a tint and its name, not an empty hole.
    @Test func aPoseWithNoPictureStillDraws() {
        let pose = StripRenderer.DuetPose(picture: nil, name: "Your pick")
        let print = StripRenderer.render([picture(.blue, CGSize(width: 300, height: 400))], layout: .duetSingle, poses: [pose])
        let corner = pixel(print, CGPoint(x: StripRenderer.margin + 4, y: StripRenderer.margin + 4))
        let paper = pixel(print, CGPoint(x: 4, y: 4))

        #expect(print.size == CGSize(width: 1200, height: 3280))
        #expect(corner != paper)
    }

    @Test func aDuetLayoutTurnsTheScoreOn() {
        let model = BoothSessionModel(capture: FakeCapture(), saver: FakeSaver(), sleep: { _ in })
        #expect(!model.showsMatchStamp)

        model.layout = .duetRow
        #expect(model.showsMatchStamp)

        // The switch still turns it off, and a change between the duet prints keeps that choice.
        model.showsMatchStamp = false
        model.layout = .duetSingle
        #expect(!model.showsMatchStamp)
    }

    /// The bands are owner decisions (2026-11-23). Each edge is tested on both sides.
    @Test func verdictBandsAreTheOwnerBands() {
        #expect(BoothSessionModel.verdict(percent: 100) == .verdictTwins)
        #expect(BoothSessionModel.verdict(percent: 90) == .verdictTwins)
        #expect(BoothSessionModel.verdict(percent: 89) == .verdictCopycat)
        #expect(BoothSessionModel.verdict(percent: 75) == .verdictCopycat)
        #expect(BoothSessionModel.verdict(percent: 74) == .verdictClose)
        #expect(BoothSessionModel.verdict(percent: 50) == .verdictClose)
        #expect(BoothSessionModel.verdict(percent: 49) == .verdictCreative)
        #expect(BoothSessionModel.verdict(percent: 25) == .verdictCreative)
        #expect(BoothSessionModel.verdict(percent: 24) == .verdictLook)
        #expect(BoothSessionModel.verdict(percent: 0) == .verdictLook)
    }

    @Test func theVerdictStampHasTheScoreAndTheVerdict() {
        let stamp = BoothSessionModel.verdictStampText(percent: 92)

        #expect(stamp.contains(BoothSessionModel.stampText(percent: 92)))
        #expect(stamp.contains(String(localized: .verdictTwins)))
    }

    @Test func theBestCopyIsTheHighestScoreAndNeedsTwoScores() {
        #expect(StripRenderer.bestIndex([40, 91, 70, nil]) == 1)
        #expect(StripRenderer.bestIndex([80, 60, 80, 10]) == 0)
        #expect(StripRenderer.bestIndex([nil, 77, nil, nil]) == nil)
        #expect(StripRenderer.bestIndex([]) == nil)
    }

    /// With scores on, the shot has a white pill at its bottom right. With scores off, the shot is plain.
    @Test func theScoreIsDrawnOnTheShot() {
        let pose = StripRenderer.DuetPose(picture: picture(.red, CGSize(width: 300, height: 400)), name: "Lean", percent: 87)
        let shot = picture(.blue, CGSize(width: 300, height: 400))
        let margin = StripRenderer.margin
        let cell = StripRenderer.singleCell
        let shotTop = 2 * margin + cell.height
        // In the right padding of the pill, halfway up: clear of the round ends and of the digits.
        let size = cell.width * 0.085
        let pillRight = margin + cell.width - cell.width * 0.05
        let pillBottom = shotTop + cell.height - cell.width * 0.05
        let inPill = CGPoint(x: pillRight - size * 0.25, y: pillBottom - size * 0.8)

        let withScore = StripRenderer.render([shot], layout: .duetSingle, poses: [pose], scores: true)
        let without = StripRenderer.render([shot], layout: .duetSingle, poses: [pose], scores: false)

        let on = pixel(withScore, inPill)
        let off = pixel(without, inPill)
        #expect(on.0 > 230 && on.1 > 230 && on.2 > 230)
        #expect(off.2 > 200 && off.0 < 60)
    }

    // MARK: The score through the model

    private nonisolated static let person = PoseSignature(bodies: [PoseSignature.Body(joints: [
        .neck: PosePoint(x: 0, y: 0.72), .root: PosePoint(x: 0, y: 0.4),
        .leftShoulder: PosePoint(x: -0.1, y: 0.7), .rightShoulder: PosePoint(x: 0.1, y: 0.7),
        .leftElbow: PosePoint(x: -0.1, y: 0.55), .leftWrist: PosePoint(x: -0.1, y: 0.4),
        .rightElbow: PosePoint(x: 0.1, y: 0.55), .rightWrist: PosePoint(x: 0.1, y: 0.4),
    ])])

    /// A finished set in a duet layout, where the detector finds the same body in each shot and pose picture,
    /// so each shot scores 100%.
    func scoredModel(_ layout: PeekCore.Layout) async -> BoothSessionModel {
        let signature = Self.person
        let model = BoothSessionModel(capture: FakeCapture(), saver: FakeSaver(), analyzePose: { _ in signature }, sleep: { _ in })
        model.layout = layout
        await model.startCamera()
        for _ in model.state.slots {
            model.send(.start)
            await model.countdownTask?.value
            await model.captureTask?.value
            model.send(.accept)
        }
        _ = await model.scoreTask?.value
        await model.stripTask?.value
        return model
    }

    /// The pixel inside the score pill of the shot of a Match print.
    func matchPillPoint() -> CGPoint {
        let margin = StripRenderer.margin
        let cell = StripRenderer.singleCell
        let size = cell.width * 0.085
        return CGPoint(
            x: margin + cell.width * 0.95 - size * 0.25,
            y: 2 * margin + 2 * cell.height - cell.width * 0.05 - size * 0.8
        )
    }

    @Test func aScoredMatchPrintHasThePillAndTheBestShot() async throws {
        let model = await scoredModel(.duetSingle)

        #expect(model.finishedShotPercents == [100, 100, 100, 100])
        // Equal scores: the first shot.
        #expect(model.duetShotIndex == 0)
        let strip = try #require(model.strip)
        #expect(strip.size == CGSize(width: 1200, height: 3280))
        let pill = pixel(strip, matchPillPoint())
        #expect(pill.0 > 230 && pill.1 > 230 && pill.2 > 230)
    }

    @Test func theScoreSwitchTakesThePillOffAScoredPrint() async throws {
        let model = await scoredModel(.duetSingle)
        let scored = try #require(model.strip)

        model.showsMatchStamp = false
        await model.stripTask?.value
        let plain = try #require(model.strip)

        #expect(plain.size == scored.size)
        #expect(pixel(plain, matchPillPoint()) != pixel(scored, matchPillPoint()))
    }

    @Test func aChosenShotDrawsAgainAndWins() async {
        let model = await scoredModel(.duetSingle)

        model.duetSlot = 2
        #expect(model.strip == nil)
        await model.stripTask?.value

        #expect(model.duetShotIndex == 2)
        #expect(model.strip?.size == CGSize(width: 1200, height: 3280))
    }

    @Test func aNewSetGoesBackToTheBestMatch() async {
        let model = await scoredModel(.duetSingle)
        model.duetSlot = 3

        model.startNewSet()

        #expect(model.duetSlot == nil)
        #expect(model.strip == nil)
    }

    @Test func aScoredDuetRowHasItsScores() async {
        let model = await scoredModel(.duetRow)

        #expect(model.matchPercent == 100)
        #expect(model.strip?.size == CGSize(width: 3552, height: 2640))
    }

    // MARK: The outer display

    /// A wide print stays in the visible 3:4 column at the right of the outer display. A narrow strip keeps
    /// the full height, as before.
    @Test func theOuterDisplayKeepsAWidePrintInTheVisibleColumn() {
        let display = CGSize(width: 800, height: 600)
        let column = StripPlacement.outerColumn(in: display, avoiding: [])
        let duet = StripRenderer.size(shotCount: 4, layout: .duetRow)

        let wide = FinishedStripView.outerFrame(in: display, avoiding: [], aspect: duet.width / duet.height)
        let narrow = FinishedStripView.outerFrame(in: display, avoiding: [], aspect: 1200 / 3744)

        #expect(wide.minX >= column.minX - 0.5)
        #expect(abs(wide.maxX - display.width) < 0.5)
        #expect(abs(narrow.height - display.height) < 0.5)
        #expect(abs(narrow.maxX - display.width) < 0.5)
    }

    // MARK: The line around each shot

    /// Black lines on cream and on white, white lines on black (owner decision, 2026-11-23).
    @Test func eachShotHasTheLineOfItsPaper() {
        let shot = picture(.blue, CGSize(width: 400, height: 300))
        let edge = CGPoint(x: StripRenderer.margin + 2, y: StripRenderer.margin + StripRenderer.cell.height / 2)
        let middle = CGPoint(x: StripRenderer.margin + StripRenderer.cell.width / 2, y: StripRenderer.margin + StripRenderer.cell.height / 2)

        for layout in [PeekCore.Layout.verticalStrip, .grid2x2] {
            let cream = pixel(StripRenderer.render([shot], layout: layout, frame: .cream), edge)
            let black = pixel(StripRenderer.render([shot], layout: layout, frame: .black), edge)
            let white = pixel(StripRenderer.render([shot], layout: layout, frame: .white), edge)
            let inside = pixel(StripRenderer.render([shot], layout: layout, frame: .cream), middle)

            #expect(cream.0 < 30 && cream.1 < 30 && cream.2 < 30)
            #expect(black.0 > 225 && black.1 > 225 && black.2 > 225)
            #expect(white.0 < 30 && white.1 < 30 && white.2 < 30)
            #expect(inside.2 > 200 && inside.0 < 60)
        }
    }

    @Test func aDuetShotHasTheLineAndThePoseKeepsItsCyanLine() {
        let pose = StripRenderer.DuetPose(picture: picture(.red, CGSize(width: 300, height: 400)), name: "Lean")
        let print = StripRenderer.render([picture(.blue, CGSize(width: 300, height: 400))], layout: .duetSingle, frame: .cream, poses: [pose])
        let margin = StripRenderer.margin
        let cell = StripRenderer.singleCell

        let shotEdge = pixel(print, CGPoint(x: margin + 2, y: 2 * margin + cell.height * 1.5))
        let poseEdge = pixel(print, CGPoint(x: margin + 2, y: margin + cell.height / 2))

        #expect(shotEdge.0 < 30 && shotEdge.1 < 30 && shotEdge.2 < 30)
        #expect(poseEdge.1 > 180 && poseEdge.2 > 180 && poseEdge.0 < 80)
    }

    // MARK: The crop follows the people (owner decision, 2026-11-24)

    /// A portrait shot: a red band at the top tenth, blue below.
    func headBand() -> UIImage {
        let size = CGSize(width: 300, height: 400)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 300, height: 48))
        }
    }

    @Test func withNoPersonTheStripKeepsTheUpperPartOfTheShot() {
        let strip = StripRenderer.render([headBand()], layout: .verticalStrip)
        // Just inside the photo line, at the top of the cell.
        let top = pixel(strip, CGPoint(x: StripRenderer.margin + StripRenderer.cell.width / 2, y: StripRenderer.margin + StripRenderer.shotBorder + 4))

        // The middle crop started below the red band; the upper crop keeps a little of it.
        #expect(top.0 > 200 && top.2 < 60)
    }

    @Test func aFocusLowInTheShotMovesTheCropDown() {
        let low = ShotFocus(eyeY: 0.9, headTopY: 0.85, centerX: 0.5)
        let strip = StripRenderer.render([headBand()], layout: .verticalStrip, focuses: [low])
        let top = pixel(strip, CGPoint(x: StripRenderer.margin + StripRenderer.cell.width / 2, y: StripRenderer.margin + StripRenderer.shotBorder + 4))

        #expect(top.2 > 200 && top.0 < 60)
    }

    /// A shot with no score gets a dash on a print where another shot has a score.
    @Test func anUnscoredShotGetsADashNextToAScoredShot() {
        let poses = [
            StripRenderer.DuetPose(picture: picture(.red, CGSize(width: 300, height: 400)), name: "A", percent: 80),
            StripRenderer.DuetPose(picture: picture(.red, CGSize(width: 300, height: 400)), name: "B", percent: nil),
        ]
        let shot = picture(.blue, CGSize(width: 300, height: 400))
        let print = StripRenderer.render([shot, shot], layout: .duetRow, poses: poses, scores: true)
        let cell = StripRenderer.duetCell
        let margin = StripRenderer.margin
        let size = cell.width * 0.085
        // The right padding of the pill of the second shot.
        let point = CGPoint(
            x: margin + 2 * (cell.width + margin) - margin - cell.width * 0.05 - size * 0.25,
            y: 2 * margin + 2 * cell.height - cell.width * 0.05 - size * 0.8
        )
        let pill = pixel(print, point)
        #expect(pill.0 > 230 && pill.1 > 230 && pill.2 > 230)

        // With no score on the whole print, there are no dashes.
        let none = poses.map { StripRenderer.DuetPose(picture: $0.picture, name: $0.name, percent: nil) }
        let plain = StripRenderer.render([shot, shot], layout: .duetRow, poses: none, scores: true)
        let empty = pixel(plain, point)
        #expect(empty.2 > 200 && empty.0 < 60)
    }

    /// A set framed too close has no score, not 0% (owner decision, 2026-11-24).
    @Test func aSetFramedTooCloseHasNoScore() async {
        let chestUp = PoseSignature(bodies: [PoseSignature.Body(joints: [
            .neck: PosePoint(x: 0, y: 0.72),
            .leftShoulder: PosePoint(x: -0.1, y: 0.7), .rightShoulder: PosePoint(x: 0.1, y: 0.7),
        ])])
        let model = BoothSessionModel(capture: FakeCapture(), saver: FakeSaver(), analyzePose: { _ in chestUp }, sleep: { _ in })
        model.layout = .duetRow
        await model.startCamera()
        for _ in model.state.slots {
            model.send(.start)
            await model.countdownTask?.value
            await model.captureTask?.value
            model.send(.accept)
        }
        _ = await model.scoreTask?.value
        await model.stripTask?.value

        #expect(model.matchPercent == nil)
        #expect(model.finishedShotPercents.allSatisfy { $0 == nil })
        // The body is still found, so each shot has a focus for its crop.
        #expect(model.shotFocus.count == 4)
    }
}
