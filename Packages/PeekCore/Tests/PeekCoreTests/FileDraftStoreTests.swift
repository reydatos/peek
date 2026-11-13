import Foundation
@testable import PeekCore
import Testing

struct FileDraftStoreTests {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)

    func take(_ slot: Int, _ name: String) -> Take {
        Take(slotID: SlotID(slot), token: CaptureToken(), assetName: name)
    }

    func record(_ takes: [Take?]) -> SessionRecord {
        SessionRecord(
            templateID: "classic",
            templateVersion: 1,
            countdown: .five,
            layout: .grid2x2,
            slots: takes.enumerated().map { Slot(id: SlotID($0.offset), cueID: "cue\($0.offset)", acceptedTake: $0.element) }
        )
    }

    @Test func committedDraftComesBackWithItsMedia() async throws {
        let store = FileDraftStore(directory: directory)
        let first = take(0, "a")
        let saved = record([first, nil])
        try await store.writeMedia(Data([1, 2, 3]), for: first)
        try await store.commit(saved)

        let loaded = try await FileDraftStore(directory: directory).loadDraft()

        #expect(loaded == saved)
        #expect(try await store.media(for: first) == Data([1, 2, 3]))
    }

    @Test func mediaWithNoCommitLeavesTheLastDraftIntact() async throws {
        let store = FileDraftStore(directory: directory)
        let first = take(0, "a")
        let saved = record([first, nil])
        try await store.writeMedia(Data([1]), for: first)
        try await store.commit(saved)
        // The app stops after the bytes of the second take, before the metadata.
        let orphan = take(1, "b")
        try await store.writeMedia(Data([2]), for: orphan)

        #expect(try await store.loadDraft() == saved)
        await #expect(throws: (any Error).self) { try await store.media(for: orphan) }
    }

    @Test func mediaWithNoDraftIsRemoved() async throws {
        let store = FileDraftStore(directory: directory)
        let orphan = take(0, "a")
        try await store.writeMedia(Data([1]), for: orphan)

        #expect(try await store.loadDraft() == nil)
        await #expect(throws: (any Error).self) { try await store.media(for: orphan) }
    }

    @Test func takeWithMissingMediaIsCleared() async throws {
        let store = FileDraftStore(directory: directory)
        let first = take(0, "a")
        let second = take(1, "b")
        try await store.writeMedia(Data([1]), for: first)
        try await store.writeMedia(Data([2]), for: second)
        try await store.commit(record([first, second]))
        try await store.deleteMedia(for: second)

        let loaded = try await store.loadDraft()

        #expect(loaded?.slots.map(\.acceptedTake) == [first, nil])
    }

    @Test func deleteDraftRemovesTheRecordAndTheMedia() async throws {
        let store = FileDraftStore(directory: directory)
        let first = take(0, "a")
        let saved = record([first])
        try await store.writeMedia(Data([1]), for: first)
        try await store.commit(saved)

        try await store.deleteDraft(UUID())
        #expect(try await store.loadDraft() == saved)

        try await store.deleteDraft(saved.id)
        #expect(try await store.loadDraft() == nil)
        await #expect(throws: (any Error).self) { try await store.media(for: first) }
    }
}
