import Observation

/// The poses that the photographer saved with the star. The newest save is first.
@Observable
final class SavedPoses {
    private(set) var ids: [String]
    private let store: (any SavedPoseStore)?

    /// The default is no store, so tests and previews stay isolated. The app passes the defaults store.
    init(store: (any SavedPoseStore)? = nil) {
        self.store = store
        ids = store?.load() ?? []
    }

    /// The saved poses that the library still has.
    var cues: [PoseCue] {
        ids.compactMap(PoseLibrary.cue(for:))
    }

    func contains(_ id: String) -> Bool {
        ids.contains(id)
    }

    func toggle(_ id: String) {
        if let index = ids.firstIndex(of: id) {
            ids.remove(at: index)
        } else {
            ids.insert(id, at: 0)
        }
        store?.save(ids)
    }
}
