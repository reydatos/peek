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

        model.startNewSet()
        #expect(model.strip == nil)
        #expect(!model.hasShots)
        #expect(model.state.phase == .ready)
    }
}
