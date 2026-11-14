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

    @Test func chosenPosesGetTheNumbersOfTheOpenSlotsInTapOrder() {
        var selection = PoseSelection(openSlots: [2, 3, 4])
        selection.toggle("walk")
        selection.toggle("lean")

        #expect(selection.ids == ["walk", "lean"])
        #expect(selection.slotNumber(for: "walk") == 2)
        #expect(selection.slotNumber(for: "lean") == 3)
        #expect(selection.slotNumber(for: "smile") == nil)

        // A second tap removes the pose. The pose after it moves to the earlier slot.
        selection.toggle("walk")
        #expect(selection.slotNumber(for: "lean") == 2)
    }

    @Test func selectionStopsAtTheNumberOfOpenSlots() {
        var selection = PoseSelection(openSlots: [4])
        selection.toggle("walk")
        selection.toggle("lean")

        #expect(selection.ids == ["walk"])
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
