import Foundation
@testable import Peek
import PeekCore
import Testing

struct DraftFailureTests {
    let store: FileDraftStore
    let flaky: FlakyDraftStore

    init() {
        store = FileDraftStore(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
        flaky = FlakyDraftStore(store)
    }

    func model(drafts: any DraftStore) -> BoothSessionModel {
        BoothSessionModel(capture: FakeCapture(), saver: FakeSaver(), drafts: drafts, sleep: { _ in })
    }

    /// Takes and accepts one shot. It does not wait for storage.
    func accept(in model: BoothSessionModel) async {
        model.send(.start)
        await model.countdownTask?.value
        await model.captureTask?.value
        model.send(.accept)
    }

    /// The number of shots that a new model brings back from storage.
    func restoredShots() async -> Int {
        let second = model(drafts: store)
        await second.restoreDraft()
        return second.state.slots.count { second.image(for: $0) != nil }
    }

    @Test func failedWriteSetsTheStatus() async throws {
        let first = model(drafts: flaky)
        await first.startCamera()
        #expect(!first.isDraftUnsaved)

        await flaky.failWrites(1)
        await accept(in: first)
        await first.persistTask?.value

        #expect(first.isDraftUnsaved)
        #expect(try await store.loadDraft() == nil)
    }

    @Test func nextShotStoresTheShotThatFailed() async {
        let first = model(drafts: flaky)
        await first.startCamera()
        await flaky.failWrites(1)
        await accept(in: first)
        await first.persistTask?.value

        await accept(in: first)
        await first.persistTask?.value

        #expect(!first.isDraftUnsaved)
        #expect(await restoredShots() == 2)
    }

    /// A second operation is in the queue before the first one fails. It must not commit a record without the bytes.
    @Test func queuedOperationWritesTheBytesOfTheFailedOne() async throws {
        let first = model(drafts: flaky)
        await first.startCamera()
        await flaky.failWrites(1)
        await accept(in: first)
        first.layout = .grid2x2
        await first.persistTask?.value

        #expect(!first.isDraftUnsaved)
        #expect(try await store.loadDraft()?.layout == .grid2x2)
        #expect(await restoredShots() == 1)
    }

    /// After the last shot, no slot changes. An event with no change must store the draft again.
    @Test func eventAfterTheLastShotStoresTheDraftAgain() async {
        let first = model(drafts: flaky)
        await first.startCamera()
        for _ in 0 ..< 3 {
            await accept(in: first)
        }
        await first.persistTask?.value
        await flaky.failWrites(1)
        await accept(in: first)
        await first.persistTask?.value
        #expect(first.isDraftUnsaved)
        #expect(await restoredShots() == 3)

        first.send(.pause(.interruption))
        await first.persistTask?.value

        #expect(!first.isDraftUnsaved)
        #expect(await restoredShots() == 4)
    }
}
