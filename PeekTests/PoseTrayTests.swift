@testable import Peek
import PeekCore
import Testing

struct PoseTrayTests {
    final class MemoryStore: SavedPoseStore {
        var ids: [String]

        init(_ ids: [String] = []) {
            self.ids = ids
        }

        func load() -> [String] {
            ids
        }

        func save(_ ids: [String]) {
            self.ids = ids
        }
    }

    @Test func savedPosesGoToTheStoreWithTheNewestFirst() {
        let store = MemoryStore(["walk"])
        let saved = SavedPoses(store: store)
        #expect(saved.contains("walk"))

        saved.toggle("lean")
        #expect(store.ids == ["lean", "walk"])
        #expect(saved.cues.map(\.id) == ["lean", "walk"])

        saved.toggle("walk")
        #expect(store.ids == ["lean"])
        #expect(SavedPoses(store: store).ids == ["lean"])
    }

    @Test func savedPoseThatTheLibraryNoLongerHasIsNotShown() {
        let saved = SavedPoses(store: MemoryStore(["gone", "smile"]))

        #expect(saved.cues.map(\.id) == ["smile"])
    }

    @Test func appliedPosesGoToTheOpenShotsOfTheBooth() async {
        let model = BoothSessionModel(capture: FakeCapture(), packID: "streetStyle", sleep: { _ in })
        await model.startCamera()
        model.send(.start)
        await model.countdownTask?.value
        await model.captureTask?.value
        model.send(.accept)
        #expect(model.openSlotNumbers == [2, 3, 4])

        model.send(.assignCues(["smile", "silly"]))

        #expect(model.state.slots.map(\.cueID) == ["walk", "smile", "silly", "yourTake"])
        #expect(model.currentCue?.id == "smile")
    }
}
