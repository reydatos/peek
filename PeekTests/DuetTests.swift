import Foundation
@testable import Peek
import PeekCore
import Testing

@MainActor
struct DuetTests {
    private let capture = FakeCapture()

    /// A booth at "ready" with a pack of the customer. Each pose has a clip.
    private func booth(isDuetOn: Bool = true) async -> BoothSessionModel {
        let still = URL(filePath: "/nowhere/still.jpg")
        let clip = URL(filePath: "/nowhere/clip.mov")
        let catalog = PoseCatalog(userPacks: [PosePack(id: "user-1", name: "Friday night", cues: [
            PoseCue(id: "user-1-a", name: "One", still: still, clip: clip),
            PoseCue(id: "user-1-b", name: "Two", still: still, clip: clip),
        ])])
        let model = BoothSessionModel(capture: capture, packID: "user-1", catalog: catalog, saver: FakeSaver(), sleep: { _ in })
        await model.startCamera()
        model.isDuetOn = isDuetOn
        return model
    }

    private func shoot(_ model: BoothSessionModel) async {
        model.send(.start)
        await model.countdownTask?.value
        await model.captureTask?.value
        // The clip goes to its shot after the recording ends.
        for _ in 0 ..< 5 {
            await Task.yield()
        }
    }

    private func exists(_ url: URL?) -> Bool {
        url.map { FileManager.default.fileExists(atPath: $0.path) } ?? false
    }

    @Test func theBoothRecordsTheCountdownOfEachShot() async {
        let model = await booth()
        #expect(model.hasPoseClips)
        await shoot(model)
        model.send(.accept)
        let clip = model.attemptClip(for: model.state.slots[0])
        #expect(exists(clip))
        // The clip has the length of the countdown, so it ends at the shot.
        #expect(await capture.clipDurations == [Double(model.countdown.seconds)])
        #expect(!model.isRecordingAttempt)
        model.startNewSet()
        #expect(!exists(clip))
    }

    @Test func theBoothRecordsNothingWithTheSwitchOff() async {
        let model = await booth(isDuetOn: false)
        await shoot(model)
        model.send(.accept)
        #expect(model.attemptClip(for: model.state.slots[0]) == nil)
        #expect(await capture.clipCount == 0)
    }

    @Test func aBuiltInPackHasNoDuet() async {
        let model = BoothSessionModel(capture: capture, saver: FakeSaver(), sleep: { _ in })
        await model.startCamera()
        model.isDuetOn = true
        #expect(!model.hasPoseClips)
        await shoot(model)
        #expect(await capture.clipCount == 0)
    }

    @Test func aRecordingFaultDoesNotStopTheShot() async {
        let model = await booth()
        await capture.failClips(true)
        await shoot(model)
        guard case .review = model.state.phase else {
            Issue.record("the shot did not reach review")
            return
        }
        model.send(.accept)
        #expect(model.attemptClip(for: model.state.slots[0]) == nil)
        #expect(!model.isRecordingAttempt)
    }

    @Test func aCancelOfTheCountdownRemovesTheClip() async {
        // The countdown waits, so the cancel comes before the shot.
        let still = URL(filePath: "/nowhere/still.jpg")
        let catalog = PoseCatalog(userPacks: [PosePack(id: "user-1", name: "Friday night", cues: [
            PoseCue(id: "user-1-a", name: "One", still: still, clip: URL(filePath: "/nowhere/clip.mov")),
        ])])
        let model = BoothSessionModel(capture: capture, packID: "user-1", catalog: catalog, saver: FakeSaver(), sleep: { _ in
            try await Task.sleep(for: .seconds(600))
        })
        await model.startCamera()
        model.isDuetOn = true
        model.send(.start)
        #expect(model.isRecordingAttempt)
        let task = model.attemptTask
        let url = await task?.value
        #expect(exists(url))
        model.send(.cancel)
        #expect(!model.isRecordingAttempt)
        for _ in 0 ..< 5 {
            await Task.yield()
        }
        #expect(!exists(url))
    }

    @Test func aRetakeRemovesTheClipOfTheOldShot() async {
        let model = await booth()
        await shoot(model)
        model.send(.accept)
        let first = model.attemptClip(for: model.state.slots[0])
        #expect(exists(first))
        model.send(.retake(model.state.slots[0].id))
        await shoot(model)
        model.send(.accept)
        let second = model.attemptClip(for: model.state.slots[0])
        #expect(exists(second))
        #expect(second != first)
    }

    @Test func aFinishedSetHasADuetOnlyForThePosesWithTheTwoClips() async {
        let model = await booth()
        await shoot(model)
        model.send(.accept)
        #expect(model.duetSegments.isEmpty, "the set is not finished")
        // The second shot has no clip of the people.
        model.isDuetOn = false
        await shoot(model)
        model.send(.accept)
        #expect(model.isComplete)
        #expect(model.duetSegments.count == 1)
        #expect(model.duetSegments[0].title.contains("1"))
    }

    @Test func aDuetThatTheAppCanNotMakeGivesAFaultAndSavesNothing() async {
        let saver = FakeSaver()
        let still = URL(filePath: "/nowhere/still.jpg")
        let catalog = PoseCatalog(userPacks: [PosePack(id: "user-1", name: "Friday night", cues: [
            PoseCue(id: "user-1-a", name: "One", still: still, clip: URL(filePath: "/nowhere/clip.mov")),
        ])])
        let model = BoothSessionModel(capture: capture, packID: "user-1", catalog: catalog, saver: saver, sleep: { _ in })
        await model.startCamera()
        model.isDuetOn = true
        await shoot(model)
        model.send(.accept)
        #expect(model.duetSegments.count == 1)
        // The clips of this test are not video.
        await model.saveDuet()
        #expect(model.saveStatus == .failed)
        #expect(await saver.savedVideos.isEmpty)
    }
}
