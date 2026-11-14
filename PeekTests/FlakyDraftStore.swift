import Foundation
import PeekCore

/// A real file store with a switch that makes the writes fail.
actor FlakyDraftStore: DraftStore {
    private let store: FileDraftStore
    /// The number of write calls that fail next.
    private var failures = 0

    init(_ store: FileDraftStore) {
        self.store = store
    }

    func failWrites(_ count: Int) {
        failures = count
    }

    private func failIfSet() throws {
        guard failures > 0 else { return }
        failures -= 1
        throw CocoaError(.fileWriteOutOfSpace)
    }

    func writeMedia(_ data: Data, for take: Take) async throws {
        try failIfSet()
        try await store.writeMedia(data, for: take)
    }

    func commit(_ session: SessionRecord) async throws {
        try failIfSet()
        try await store.commit(session)
    }

    func media(for take: Take) async throws -> Data {
        try await store.media(for: take)
    }

    func loadDraft() async throws -> SessionRecord? {
        try await store.loadDraft()
    }

    func deleteMedia(for take: Take) async throws {
        try await store.deleteMedia(for: take)
    }

    func deleteDraft(_ id: SessionRecord.ID) async throws {
        try await store.deleteDraft(id)
    }
}
