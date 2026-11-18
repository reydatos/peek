@testable import Peek
import PeekCore
import Testing
import UIKit

struct FinishedStripTests {
    /// Takes and accepts all four shots of the Classic pack.
    func completedModel(saver: FakeSaver) async -> BoothSessionModel {
        let model = BoothSessionModel(capture: FakeCapture(), saver: saver, sleep: { _ in })
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

    @Test func fourAcceptedShotsMakeAStripOfTheDesignSize() async {
        let model = await completedModel(saver: FakeSaver())

        #expect(model.state.phase == .complete)
        #expect(model.strip?.size == CGSize(width: 1200, height: 3744))
        #expect(model.strip?.scale == 1)
        #expect(model.stillImage === model.strip)
    }

    @Test func stripIsAtLeastThePRDMinimum() {
        let size = StripRenderer.size(shotCount: 4)
        #expect(size.width >= 600)
        #expect(size.height >= 1800)
    }

    @Test func gridLayoutDrawsTheShotsTwoByTwo() async {
        let model = await completedModel(saver: FakeSaver())
        await model.saveStrip()

        model.layout = .grid2x2
        #expect(model.strip == nil)
        await model.stripTask?.value

        #expect(model.strip?.size == CGSize(width: 2352, height: 1992))
        #expect(model.saveStatus == .idle)
    }

    @Test func gridWithOneShotHasOneCell() {
        #expect(StripRenderer.size(shotCount: 1, layout: .grid2x2) == CGSize(width: 1200, height: 1116))
        #expect(StripRenderer.render([UIImage()], layout: .grid2x2).size == CGSize(width: 1200, height: 1116))
    }

    @Test func saveStripSendsOnePictureAndReportsSaved() async {
        let saver = FakeSaver()
        let model = await completedModel(saver: saver)

        await model.saveStrip()

        #expect(model.saveStatus == .saved)
        let saved = await saver.saved
        #expect(saved.count == 1)
        #expect(saved.first?.count == 1)
        #expect(saved.first?.first.flatMap(UIImage.init(data:))?.size == CGSize(width: 1200, height: 3744))
    }

    @Test func saveShotsSendsTheCameraBytesOfEachShot() async {
        let saver = FakeSaver()
        let model = await completedModel(saver: saver)

        await model.saveShots()

        #expect(await saver.saved == [Array(repeating: FakeCapture.photoData, count: 4)])
    }

    @Test func deniedPhotosAccessIsReported() async {
        let model = await completedModel(saver: FakeSaver(error: .denied))

        await model.saveStrip()

        #expect(model.saveStatus == .denied)
    }

    @Test func retakeDropsTheStripAndNewSetClearsTheShots() async {
        let model = await completedModel(saver: FakeSaver())

        model.send(.retake(model.state.slots[1].id))
        #expect(model.strip == nil)
        #expect(model.stripTask == nil)

        model.startNewSet()
        #expect(model.strip == nil)
        #expect(!model.hasShots)
        #expect(model.state.phase == .ready)
    }

    /// A layout change during the draw must not leave the picture of the old layout.
    @Test func layoutChangeDuringTheDrawKeepsOnlyTheNewLayout() async {
        let model = BoothSessionModel(capture: FakeCapture(), saver: FakeSaver(), sleep: { _ in })
        await model.startCamera()
        for _ in model.state.slots {
            model.send(.start)
            await model.countdownTask?.value
            await model.captureTask?.value
            model.send(.accept)
        }
        let first = model.stripTask
        model.layout = .grid2x2
        await first?.value
        await model.stripTask?.value

        #expect(model.strip?.size == CGSize(width: 2352, height: 1992))
    }

    @Test func saveStripWaitsForTheDraw() async {
        let saver = FakeSaver()
        let model = await completedModel(saver: saver)
        model.layout = .grid2x2

        await model.saveStrip()

        #expect(model.saveStatus == .saved)
        #expect(await saver.saved.first?.first.flatMap(UIImage.init(data:))?.size == CGSize(width: 2352, height: 1992))
    }

    /// The strip is a picture. Its paper and its text must not follow dark mode.
    @Test func stripColorsAreTheSameInLightAndDarkMode() {
        let light = UITraitCollection(userInterfaceStyle: .light)
        let dark = UITraitCollection(userInterfaceStyle: .dark)

        for frame in FrameColor.allCases {
            let style = StripRenderer.Style.paper(frame)
            #expect(style.paper.resolvedColor(with: light) == style.paper.resolvedColor(with: dark))
            #expect(style.ink.resolvedColor(with: light) == style.ink.resolvedColor(with: dark))
            #expect(style.wordmark != nil)
            // The text must be readable on the paper.
            #expect(style.paper.resolvedColor(with: light) != style.ink.resolvedColor(with: light))
        }
    }

    @Test func frameColorChangeDrawsTheStripAgainOnTheNewPaper() async throws {
        let model = await completedModel(saver: FakeSaver())
        await model.saveStrip()
        let cream = try #require(model.strip)

        model.frame = .black
        #expect(model.strip == nil)
        #expect(model.saveStatus == .idle)
        await model.stripTask?.value

        let black = try #require(model.strip)
        #expect(black.size == cream.size)
        #expect(cornerPixel(of: black) != cornerPixel(of: cream))
    }

    /// The color of the top left pixel: the paper.
    func cornerPixel(of image: UIImage) -> [UInt8] {
        var pixel = [UInt8](repeating: 0, count: 4)
        let context = CGContext(
            data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        if let cgImage = image.cgImage {
            context?.draw(cgImage, in: CGRect(x: 0, y: -CGFloat(cgImage.height - 1), width: CGFloat(cgImage.width), height: CGFloat(cgImage.height)))
        }
        return pixel
    }

    /// A booth with four accepted shots, where the detector gives this body shape for each picture.
    private func scoredModel(_ signature: PoseSignature?) async -> BoothSessionModel {
        let model = BoothSessionModel(capture: FakeCapture(), saver: FakeSaver(), analyzePose: { _ in signature }, sleep: { _ in })
        await model.startCamera()
        for _ in 0 ..< 4 {
            model.send(.start)
            await model.countdownTask?.value
            await model.captureTask?.value
            model.send(.accept)
        }
        await model.stripTask?.value
        _ = await model.scoreTask?.value
        return model
    }

    private nonisolated static let person = PoseSignature(bodies: [PoseSignature.Body(joints: [
        .neck: PosePoint(x: 0, y: 0.72), .root: PosePoint(x: 0, y: 0.4),
        .leftShoulder: PosePoint(x: -0.1, y: 0.7), .rightShoulder: PosePoint(x: 0.1, y: 0.7),
        .leftElbow: PosePoint(x: -0.1, y: 0.55), .leftWrist: PosePoint(x: -0.1, y: 0.4),
        .rightElbow: PosePoint(x: 0.1, y: 0.55), .rightWrist: PosePoint(x: 0.1, y: 0.4),
    ])])

    @Test func aFinishedSetHasItsMatchScore() async {
        let model = await scoredModel(Self.person)
        // The shots and the pose pictures have the same body shape.
        #expect(model.matchPercent == 100)
        #expect(BoothSessionModel.stampText(percent: 92).contains("92"))
    }

    @Test func aSetWithNoPersonInItsPosePicturesHasNoScore() async {
        let model = await scoredModel(nil)
        #expect(model.matchPercent == nil)
    }

    @Test func theStampSwitchDrawsThePictureAgainAtTheSameSize() async throws {
        let model = await scoredModel(Self.person)
        let plain = try #require(model.strip)
        model.showsMatchStamp = true
        #expect(model.strip == nil)
        await model.stripTask?.value
        let stamped = try #require(model.strip)
        #expect(stamped.size == plain.size)
        #expect(stamped.pngData() != plain.pngData())
    }

    @Test func aRetakeAfterTheLastShotDropsTheScore() async {
        let model = await scoredModel(Self.person)
        model.send(.retake(model.state.slots[0].id))
        #expect(model.matchPercent == nil)
        #expect(model.scoreTask == nil)
    }

    @Test func theStampIsInTheFooterOnly() throws {
        let shots = [UIImage(), UIImage()]
        let date = Date(timeIntervalSince1970: 0)
        let plain = StripRenderer.render(shots, date: date)
        let stamped = StripRenderer.render(shots, date: date, stamp: "92% match")
        #expect(stamped.size == plain.size)
        #expect(stamped.pngData() != plain.pngData())
        // The part above the footer is the same.
        let top = CGRect(x: 0, y: 0, width: plain.size.width, height: plain.size.height - StripRenderer.footer)
        let plainTop = try #require(plain.cgImage?.cropping(to: top))
        let stampedTop = try #require(stamped.cgImage?.cropping(to: top))
        #expect(UIImage(cgImage: plainTop).pngData() == UIImage(cgImage: stampedTop).pngData())
    }
}
