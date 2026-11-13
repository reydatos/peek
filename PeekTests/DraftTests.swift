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
        await accept(2, in: first)

        let second = model()
        await second.restoreDraft()
        await second.startCamera()

        #expect(second.state.phase == .paused(resumeTo: .ready, reason: .recovered))
        #expect(second.packID == "streetStyle")
        #expect(second.layout == .grid2x2)
        #expect(second.state.slots.map { second.image(for: $0) != nil } == [true, true, false, false])
        #expect(second.state.currentSlotID == SlotID(2))

        second.send(.resume)
        await accept(2, in: second)
        #expect(second.strip?.size == CGSize(width: 2352, height: 1992))
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
        #expect(second.strip?.size == CGSize(width: 1200, height: 3744))
        await second.saveShots()
        #expect(await saver.saved == [Array(repeating: FakeCapture.photoData, count: 4)])
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
