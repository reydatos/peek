import Foundation
import PeekCore

/// The one place on the device that holds the booth draft.
enum BoothDraftStore {
    static let shared = FileDraftStore(directory: .applicationSupportDirectory.appending(path: "Draft"))

    /// True when storage holds a draft with one accepted shot or more.
    static func hasDraft() async -> Bool {
        let record = try? await shared.loadDraft()
        return record?.slots.contains { $0.acceptedTake != nil } ?? false
    }
}
