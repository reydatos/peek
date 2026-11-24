import Foundation
@testable import Peek
import PeekCore
import Testing
import UIKit

struct DraftTests {
    let store = FileDraftStore(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))

    func model() -> BoothSessionModel {
        BoothSessionModel(capture: FakeCapture(), saver: FakeSaver(), drafts: store, sleep: { _ in })
    }

    /// Takes and accepts shots, then waits for storage.
    func accept(_ count: Int, in model: BoothSessionModel) async {
        for _ in 0 ..< count {
            model.send(.start)
            await model.countdownTask?.value
            await model.captureTask?.value
            model.send(.accept)
        }
        await model.persistTask?.value
    }

    @Test func acceptedShotsComeBackAndWaitForResume() async {
        let first = model()
        await first.startCamera()
        first.loadPack("streetStyle")
        first.layout = .grid2x2
        first.frame = .black
        await accept(2, in: first)

        let second = model()
        await second.restoreDraft()
        await second.startCamera()

        #expect(second.state.phase == .paused(resumeTo: .ready, reason: .recovered))
        #expect(second.packID == "streetStyle")
        #expect(second.layout == .grid2x2)
        #expect(second.frame == .black)
        #expect(second.state.slots.map { second.image(for: $0) != nil } == [true, true, false, false])
        #expect(second.state.currentSlotID == SlotID(2))

        second.send(.resume)
        await accept(2, in: second)
        await second.stripTask?.value
        #expect(second.strip?.size == CGSize(width: 2352, height: 1992))
    }

    @Test func newBoothRemovesTheStoredDraft() async throws {
        let first = model()
        await first.startCamera()
        await accept(2, in: first)

        let second = model()
        await second.discardStoredDraft()
        await second.startCamera()

        #expect(second.state.phase == .ready)
        #expect(second.state.slots.allSatisfy { $0.acceptedTake == nil })
        #expect(try await store.loadDraft() == nil)
    }

    @Test func finishedSetComesBackWithItsStripAndItsShots() async {
        let first = model()
        await first.startCamera()
        await accept(4, in: first)

        let saver = FakeSaver()
        let second = BoothSessionModel(capture: FakeCapture(), saver: saver, drafts: store, sleep: { _ in })
        await second.restoreDraft()
        await second.startCamera()

        #expect(second.state.phase == .complete)
        await second.stripTask?.value
        #expect(second.strip?.size == CGSize(width: 1200, height: 3744))
        await second.saveShots()
        #expect(await saver.saved == [Array(repeating: FakeCapture.photoData, count: 4)])
    }

    @Test func aSavedFinishedSetDoesNotComeBack() async throws {
        let first = model()
        await first.startCamera()
        await accept(4, in: first)
        await first.saveStrip()
        await first.persistTask?.value
        #expect(first.saveStatus == .saved)
        // The finished set stays on the screen after the save.
        #expect(first.isComplete)

        #expect(try await store.loadDraft() == nil)
        let second = model()
        await second.restoreDraft()
        await second.startCamera()
        #expect(second.state.phase == .ready)
    }

    @Test func aDraftThatCameBackContinuesAtReadyWithNoExtraStep() async {
        let first = model()
        await first.startCamera()
        await accept(2, in: first)

        let second = model()
        await second.restoreDraft()
        await second.startCamera()
        second.continueIfWaiting()
        #expect(second.state.phase == .ready)
        #expect(second.state.currentSlotID == SlotID(2))
    }

    @Test func theBoothContinuesAfterTheAppComesBackButACountdownWaits() async {
        let waiting = BoothSessionModel(capture: FakeCapture(), saver: FakeSaver(), sleep: { _ in try await Task.sleep(for: .seconds(3600)) })
        await waiting.startCamera()
        waiting.send(.pause(.interruption))
        waiting.continueIfWaiting()
        #expect(waiting.state.phase == .ready)

        waiting.send(.start)
        waiting.send(.pause(.interruption))
        waiting.continueIfWaiting()
        #expect(waiting.state.phase == .paused(resumeTo: .countdown, reason: .interruption))
    }

    @Test func theCameraStartsAgainAfterAFault() async {
        let model = BoothSessionModel(capture: FakeCapture(startError: .permissionDenied), saver: FakeSaver())
        await model.startCamera()
        #expect(model.cameraStatus == .denied)
        // The fake camera fails each time, so the retry gives the same status, not `idle`.
        await model.retryCamera()
        #expect(model.cameraStatus == .denied)
    }

    @Test func aDraftOfARemovedCustomerPackComesBackWithTheFreePoses() async {
        let still = URL(filePath: "/dev/null/still.jpg")
        let catalog = PoseCatalog(userPacks: [PosePack(id: "user-1", name: "Friday night", cues: [
            PoseCue(id: "user-1-a", name: "One", still: still),
            PoseCue(id: "user-1-b", name: "Two", still: still),
        ])])
        let first = BoothSessionModel(capture: FakeCapture(), packID: "user-1", catalog: catalog, saver: FakeSaver(), drafts: store, sleep: { _ in })
        await first.startCamera()
        await accept(1, in: first)

        // The customer removed the pack. The next launch has a catalog with no such pack.
        let second = model()
        await second.restoreDraft()
        await second.startCamera()
        #expect(second.packID == PoseLibrary.freeID)
        #expect(second.state.slots.map(\.cueID) == ["walk", "lookBack"])
        #expect(second.state.slots.first.flatMap { second.image(for: $0) } != nil)
        #expect(second.currentCue != nil)
    }

    @Test func newSetDeletesTheDraft() async throws {
        let first = model()
        await first.startCamera()
        await accept(4, in: first)
        #expect(try await store.loadDraft() != nil)

        first.startNewSet()
        await first.persistTask?.value

        #expect(try await store.loadDraft() == nil)
        let second = model()
        await second.restoreDraft()
        await second.startCamera()
        #expect(second.state.phase == .ready)
        #expect(!second.hasShots)
    }

    @Test func redoOfAnAcceptedShotKeepsOnlyTheMediaInUse() async throws {
        let first = model()
        await first.startCamera()
        await accept(1, in: first)
        let old = try #require(first.state.slots[0].acceptedTake)

        // Two more takes of slot one push the first take out of the undo history.
        for _ in 0 ..< 2 {
            first.send(.retake(SlotID(0)))
            await accept(1, in: first)
        }

        await #expect(throws: (any Error).self) { try await store.media(for: old) }
        let record = try #require(try await store.loadDraft())
        #expect(record.slots[0].acceptedTake == first.state.slots[0].acceptedTake)
        #expect(record.slots[0].previousTake == first.state.slots[0].previousTake)
    }
}
