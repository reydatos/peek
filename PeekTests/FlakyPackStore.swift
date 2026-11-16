import Foundation
import PeekCore

/// A pack store that can refuse the next commits. It wraps a file store.
actor FlakyPackStore: PackStore {
    private let store: FilePackStore
    private var failures = 0

    init(_ store: FilePackStore) {
        self.store = store
    }

    func failCommits(_ count: Int) {
        failures = count
    }

    func writeMedia(_ data: Data, named name: String, for packID: UserPack.ID) async throws {
        try await store.writeMedia(data, named: name, for: packID)
    }

    func commit(_ pack: UserPack) async throws {
        if failures > 0 {
            failures -= 1
            throw CocoaError(.fileWriteOutOfSpace)
        }
        try await store.commit(pack)
    }

    func loadPacks() async throws -> [UserPack] {
        try await store.loadPacks()
    }

    func deletePack(_ id: UserPack.ID) async throws {
        try await store.deletePack(id)
    }

    nonisolated func mediaURL(named name: String, for packID: UserPack.ID) -> URL {
        store.mediaURL(named: name, for: packID)
    }
}
