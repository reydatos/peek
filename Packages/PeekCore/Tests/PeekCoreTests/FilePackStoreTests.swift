import Foundation
@testable import PeekCore
import Testing

struct FilePackStoreTests {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)

    func pack(_ name: String = "Friday night", poses: Int = 4) -> UserPack {
        UserPack(name: name, poses: (0 ..< poses).map { UserPose(name: "Pose \($0)", stillFile: "\($0).jpg", clipFile: "\($0).mov") })
    }

    /// Writes each media file of the pack, then the record.
    func store(_ pack: UserPack, in store: FilePackStore) async throws {
        for name in pack.mediaFiles {
            try await store.writeMedia(Data(name.utf8), named: name, for: pack.id)
        }
        try await store.commit(pack)
    }

    @Test func aStoredPackComesBackWithItsMedia() async throws {
        let saved = pack()
        try await store(saved, in: FilePackStore(directory: directory))

        let second = FilePackStore(directory: directory)
        let loaded = try await second.loadPacks()
        #expect(loaded == [saved])
        let still = second.mediaURL(named: "0.jpg", for: saved.id)
        #expect(try Data(contentsOf: still) == Data("0.jpg".utf8))
    }

    @Test func packsComeBackByName() async throws {
        let store = FilePackStore(directory: directory)
        try await self.store(pack("Zoo"), in: store)
        try await self.store(pack("Arcade"), in: store)
        #expect(try await store.loadPacks().map(\.name) == ["Arcade", "Zoo"])
    }

    @Test func aPackWithAMissingMediaFileIsLeftOut() async throws {
        let store = FilePackStore(directory: directory)
        let saved = pack()
        try await self.store(saved, in: store)
        try FileManager.default.removeItem(at: store.mediaURL(named: "2.mov", for: saved.id))
        #expect(try await store.loadPacks().isEmpty)
    }

    @Test func mediaWithNoRecordIsNotAPack() async throws {
        let store = FilePackStore(directory: directory)
        try await store.writeMedia(Data([1]), named: "0.jpg", for: UUID())
        #expect(try await store.loadPacks().isEmpty)
    }

    @Test func aCommitRemovesTheMediaThatTheRecordDoesNotUse() async throws {
        let store = FilePackStore(directory: directory)
        var saved = pack()
        try await self.store(saved, in: store)
        // The customer records pose 0 again. The new files have new names.
        saved.poses[0].stillFile = "new.jpg"
        saved.poses[0].clipFile = "new.mov"
        try await store.writeMedia(Data([9]), named: "new.jpg", for: saved.id)
        try await store.writeMedia(Data([9]), named: "new.mov", for: saved.id)
        try await store.commit(saved)

        #expect(try await store.loadPacks() == [saved])
        #expect(!FileManager.default.fileExists(atPath: store.mediaURL(named: "0.jpg", for: saved.id).path))
        #expect(!FileManager.default.fileExists(atPath: store.mediaURL(named: "0.mov", for: saved.id).path))
    }

    @Test func aDeletedPackDoesNotComeBack() async throws {
        let store = FilePackStore(directory: directory)
        let saved = pack()
        try await self.store(saved, in: store)
        try await store.deletePack(saved.id)
        #expect(try await store.loadPacks().isEmpty)
        #expect(!FileManager.default.fileExists(atPath: store.mediaURL(named: "0.jpg", for: saved.id).path))
    }

    @Test func aMediaNameWithAPathIsRefused() async throws {
        let store = FilePackStore(directory: directory)
        await #expect(throws: (any Error).self) {
            try await store.writeMedia(Data([1]), named: "../escape.jpg", for: UUID())
        }
        var bad = pack()
        bad.poses[0].stillFile = "../../escape.jpg"
        await #expect(throws: (any Error).self) {
            try await store.commit(bad)
        }
    }

    @Test func aPackIsCompleteWithANameAndFourPoses() {
        #expect(pack().isComplete)
        #expect(!pack(poses: 3).isComplete)
        #expect(!pack("  ").isComplete)
    }
}
