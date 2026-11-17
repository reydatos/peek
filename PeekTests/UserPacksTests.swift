import Foundation
@testable import Peek
import PeekCore
import Testing

@MainActor struct UserPacksTests {
    let store = FilePackStore(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))

    /// A draft with a name and four recorded poses. Each clip is a small file in the temporary folder.
    func draft(name: String = "Friday night") throws -> PackDraft {
        let draft = PackDraft()
        draft.name = name
        for index in draft.poses.indices {
            let clip = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mov")
            try Data("clip \(index)".utf8).write(to: clip)
            draft.setRecording(still: FakeCapture.photoData, clipURL: clip, at: index)
        }
        draft.poses[0].name = "  The lean back "
        return draft
    }

    @Test func aDraftIsCompleteWithANameAndFourRecordings() throws {
        let draft = PackDraft()
        #expect(draft.poses.count == 4)
        #expect(!draft.isComplete)
        let full = try self.draft()
        #expect(full.isComplete)
        full.name = "   "
        #expect(!full.isComplete)
    }

    @Test func aSavedPackIsInTheCatalogAndComesBackAfterARestart() async throws {
        let catalog = PoseCatalog()
        let packs = UserPacks(catalog: catalog, store: store)
        await packs.load()
        #expect(packs.isLoaded)
        #expect(catalog.userPacks.isEmpty)

        let id = try #require(try await packs.save(draft()))
        #expect(id.hasPrefix(UserPacks.idPrefix))
        let pack = try #require(catalog.pack(id: id))
        #expect(pack.category == .mine)
        #expect(pack.cues.count == 4)
        // The app makes the pose IDs, and each one is a customer ID.
        #expect(pack.cues.allSatisfy { $0.id.hasPrefix(UserPacks.idPrefix) })
        #expect(Set(pack.cues.map(\.id)).count == 4)
        // The clip and the still picture are files of the pack.
        let clip = try #require(pack.cues[0].clipURL)
        #expect(try Data(contentsOf: clip) == Data("clip 0".utf8))
        #expect(pack.cues[0].picture != nil)

        // A new launch reads the same pack from storage.
        let second = PoseCatalog()
        await UserPacks(catalog: second, store: store).load()
        #expect(second.pack(id: id)?.cues.map(\.id) == pack.cues.map(\.id))
    }

    @Test func aPoseWithNoNameGetsItsNumber() async throws {
        let catalog = PoseCatalog()
        let packs = UserPacks(catalog: catalog, store: store)
        let id = try #require(try await packs.save(draft()))
        let stored = try #require(try await store.loadPacks().first)
        #expect(stored.poses.map(\.name) == ["The lean back", "Pose 2", "Pose 3", "Pose 4"])
        #expect(stored.name == "Friday night")
        #expect(catalog.pack(id: id) != nil)
    }

    @Test func aDraftThatIsNotCompleteIsNotSaved() async throws {
        let packs = UserPacks(catalog: PoseCatalog(), store: store)
        let draft = try draft()
        draft.poses[3].clipURL = nil
        #expect(await packs.save(draft) == nil)
        #expect(try await store.loadPacks().isEmpty)
    }

    @Test func aSaveThatFailsKeepsTheRecordingsAndASecondSaveWorks() async throws {
        let flaky = FlakyPackStore(store)
        await flaky.failCommits(1)
        let catalog = PoseCatalog()
        let packs = UserPacks(catalog: catalog, store: flaky)
        let draft = try draft()
        let clips = draft.poses.compactMap(\.clipURL)

        #expect(await packs.save(draft) == nil)
        // The draft still has its four clips, and storage has no part of a pack.
        #expect(draft.isComplete)
        #expect(clips.allSatisfy { FileManager.default.fileExists(atPath: $0.path) })
        #expect(try await store.loadPacks().isEmpty)

        let id = try #require(await packs.save(draft))
        #expect(catalog.pack(id: id)?.cues.count == 4)
        // The pack is stored, so the temporary clips are gone.
        #expect(clips.allSatisfy { !FileManager.default.fileExists(atPath: $0.path) })
    }

    @Test func aDeletedPackLeavesTheCatalogAndStorage() async throws {
        let catalog = PoseCatalog()
        let packs = UserPacks(catalog: catalog, store: store)
        let id = try #require(try await packs.save(draft()))
        await packs.delete(packID: id)
        #expect(catalog.pack(id: id) == nil)
        #expect(try await store.loadPacks().isEmpty)
        // A built-in pack ID does nothing.
        await packs.delete(packID: PoseLibrary.classicID)
        #expect(catalog.pack(id: PoseLibrary.classicID) != nil)
    }

    @Test func aBoothUsesACustomerPackAndLeavesItBeforeADelete() async throws {
        let catalog = PoseCatalog()
        let packs = UserPacks(catalog: catalog, store: store)
        let id = try #require(try await packs.save(draft()))
        let model = BoothSessionModel(capture: FakeCapture(), catalog: catalog, saver: FakeSaver())
        await model.startCamera()
        model.loadPack(id)
        #expect(model.packID == id)
        #expect(model.state.slots.count == 4)
        #expect(model.currentCue?.clipURL != nil)

        // The booth leaves the pack first, as `BoothView` does, then the pack goes away.
        model.loadPack(PoseLibrary.classicID)
        await packs.delete(packID: id)
        #expect(model.currentCue?.id == "smile")
    }

    @Test func aRecordingCountsDownThenGivesAClipAndAPicture() async throws {
        let capture = FakeCapture()
        let recording = PoseRecording(capture: capture, sleep: { _ in })
        #expect(recording.phase == .ready)
        recording.start()
        await recording.task?.value
        #expect(recording.phase == .done)
        #expect(await capture.clipCount == 1)
        let result = try #require(recording.takeResult())
        #expect(result.still == FakeCapture.photoData)
        #expect(FileManager.default.fileExists(atPath: result.clipURL.path))
        // The caller owns the clip now. A second take gives nothing.
        #expect(recording.takeResult() == nil)
    }

    @Test func aRecordingThatFailsCanStartAgain() async {
        let capture = FakeCapture()
        await capture.failClips(true)
        let recording = PoseRecording(capture: capture, sleep: { _ in })
        recording.start()
        await recording.task?.value
        #expect(recording.phase == .failed)
        #expect(recording.takeResult() == nil)

        await capture.failClips(false)
        recording.start()
        await recording.task?.value
        #expect(recording.phase == .done)
    }

    @Test func aCancelInTheCountdownRecordsNothing() async {
        let capture = FakeCapture()
        let recording = PoseRecording(capture: capture, sleep: { _ in try await Task.sleep(for: .seconds(3600)) })
        recording.start()
        await Task.yield()
        recording.cancel()
        #expect(recording.phase == .ready)
        #expect(await capture.clipCount == 0)
    }
}
