import Foundation
import Observation
import PeekCore

/// The pose packs that the customer made. It reads and writes them in storage, and it gives them to the catalog.
@Observable
final class UserPacks {
    /// The prefix of the ID of a customer pack and of a customer pose. The app makes these IDs; it does not take
    /// an ID from a file. So a customer ID is never the same as a built-in ID.
    static let idPrefix = "user-"

    let catalog: PoseCatalog
    private let store: (any PackStore)?
    /// True after the first read of storage. The booth starts after that, so a stored set finds its pack.
    private(set) var isLoaded = false

    /// The default is no store, so tests and previews stay isolated. The app passes the file store.
    init(catalog: PoseCatalog, store: (any PackStore)? = nil) {
        self.catalog = catalog
        self.store = store
    }

    static func packID(_ id: UserPack.ID) -> String {
        idPrefix + id.uuidString
    }

    /// Reads the packs from storage and puts them in the catalog.
    func load() async {
        defer { isLoaded = true }
        guard let store else { return }
        let packs = await (try? store.loadPacks()) ?? []
        catalog.userPacks = packs.filter(\.isComplete).map { pack in
            PosePack(id: Self.packID(pack.id), name: pack.name, cues: pack.poses.map { pose in
                PoseCue(
                    id: Self.idPrefix + pose.id.uuidString,
                    name: pose.name,
                    still: store.mediaURL(named: pose.stillFile, for: pack.id),
                    clip: pose.clipFile.map { store.mediaURL(named: $0, for: pack.id) }
                )
            })
        }
    }

    /// Stores a pack that the customer made, and gives the ID of the new pack in the catalog.
    /// Nil when the pack is not complete or storage refused it.
    func save(_ draft: PackDraft) async -> String? {
        guard let store, draft.isComplete else { return nil }
        let id = UUID()
        var poses: [UserPose] = []
        do {
            for (index, pose) in draft.poses.enumerated() {
                guard let still = pose.still, let clipURL = pose.clipURL else { return nil }
                let poseID = UUID()
                let name = pose.name.trimmingCharacters(in: .whitespacesAndNewlines)
                try await store.writeMedia(still, named: "\(poseID.uuidString).jpg", for: id)
                // The clip stays in the temporary folder until the record is stored, so a fault loses no recording.
                try await store.writeMedia(Data(contentsOf: clipURL), named: "\(poseID.uuidString).mov", for: id)
                poses.append(UserPose(
                    id: poseID,
                    name: name.isEmpty ? String(localized: .poseNumber(index + 1)) : name,
                    stillFile: "\(poseID.uuidString).jpg",
                    clipFile: "\(poseID.uuidString).mov"
                ))
            }
            let pack = UserPack(id: id, name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines), poses: poses)
            try await store.commit(pack)
        } catch {
            // A pack with no record is not a pack. Its files go away. The draft keeps its recordings.
            try? await store.deletePack(id)
            return nil
        }
        draft.discard()
        await load()
        return Self.packID(id)
    }

    /// Removes a customer pack from storage and from the catalog.
    func delete(packID: String) async {
        guard let store, packID.hasPrefix(Self.idPrefix), let id = UUID(uuidString: String(packID.dropFirst(Self.idPrefix.count)))
        else { return }
        try? await store.deletePack(id)
        await load()
    }
}
