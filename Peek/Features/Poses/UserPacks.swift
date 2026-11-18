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
    /// Examines the pictures and the clips of a pack file from a different phone.
    private let checkMedia: @Sendable (PackFile) async -> Bool

    /// The default is no store, so tests and previews stay isolated. The app passes the file store.
    init(
        catalog: PoseCatalog,
        store: (any PackStore)? = nil,
        checkMedia: @escaping @Sendable (PackFile) async -> Bool = PackMediaCheck.isUsable
    ) {
        self.catalog = catalog
        self.store = store
        self.checkMedia = checkMedia
    }

    static func packID(_ id: UserPack.ID) -> String {
        idPrefix + id.uuidString
    }

    /// The storage ID of a customer pack. Nil for a built-in pack.
    static func uuid(of packID: String) -> UserPack.ID? {
        packID.hasPrefix(idPrefix) ? UUID(uuidString: String(packID.dropFirst(idPrefix.count))) : nil
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
    /// Nil when the pack is not complete or storage refused it. The draft then keeps its recordings.
    func save(_ draft: PackDraft) async -> String? {
        guard draft.isComplete else { return nil }
        var poses: [PackFile.Pose] = []
        for pose in draft.poses {
            // The clip stays in the temporary folder until the record is stored, so a fault loses no recording.
            guard let still = pose.still, let clipURL = pose.clipURL, let clip = try? Data(contentsOf: clipURL) else { return nil }
            poses.append(PackFile.Pose(name: pose.name, still: still, clip: clip))
        }
        guard let id = await store(name: draft.name, poses: poses) else { return nil }
        draft.discard()
        return id
    }

    /// Stores a pack from a pack file, and gives the ID of the new pack in the catalog.
    /// The app makes new IDs and new file names. It takes none from the file.
    func add(_ file: PackFile) async -> String? {
        await store(name: file.name, poses: file.poses)
    }

    private func store(name: String, poses: [PackFile.Pose]) async -> String? {
        let packName = PackFile.cleanName(name)
        // A pack with no name does not come back from storage, so it is not stored.
        guard let store, poses.count == UserPack.poseCount, !packName.isEmpty else { return nil }
        let id = UUID()
        var records: [UserPose] = []
        do {
            for (index, pose) in poses.enumerated() {
                let poseID = UUID()
                let poseName = PackFile.cleanName(pose.name)
                try await store.writeMedia(pose.still, named: "\(poseID.uuidString).jpg", for: id)
                try await store.writeMedia(pose.clip, named: "\(poseID.uuidString).mov", for: id)
                records.append(UserPose(
                    id: poseID,
                    name: poseName.isEmpty ? String(localized: .poseNumber(index + 1)) : poseName,
                    stillFile: "\(poseID.uuidString).jpg",
                    clipFile: "\(poseID.uuidString).mov"
                ))
            }
            try await store.commit(UserPack(id: id, name: packName, poses: records))
        } catch {
            // A pack with no record is not a pack. Its files go away.
            try? await store.deletePack(id)
            return nil
        }
        await load()
        return Self.packID(id)
    }

    // MARK: Pack files

    /// The pack as the content of a pack file. Nil when the pack is not in storage or a file of it can not be read.
    func file(forPackID packID: String) async -> PackFile? {
        guard let store, let id = Self.uuid(of: packID),
              let pack = await (try? store.loadPacks())?.first(where: { $0.id == id })
        else { return nil }
        // A pack that an older build stored can have a name that a file does not accept.
        let name = PackFile.cleanName(pack.name)
        let sources = pack.poses.map { pose in
            (PackFile.cleanName(pose.name), store.mediaURL(named: pose.stillFile, for: id), pose.clipFile.map { store.mediaURL(named: $0, for: id) })
        }
        return await Task.detached {
            var poses: [PackFile.Pose] = []
            for (poseName, stillURL, clipURL) in sources {
                guard let clipURL, let still = try? Data(contentsOf: stillURL), let clip = try? Data(contentsOf: clipURL)
                else { return nil }
                poses.append(PackFile.Pose(name: poseName, still: still, clip: clip))
            }
            return PackFile(name: name, poses: poses)
        }.value
    }

    /// Writes the pack file of a pack to the temporary folder, for the Share button.
    func exportFile(packID: String) async -> URL? {
        guard let file = await file(forPackID: packID) else { return nil }
        return await Task.detached {
            // The file name comes from the pack name, with no character that divides a path.
            let safe = file.name.components(separatedBy: CharacterSet(charactersIn: "/\\:")).joined(separator: "-")
            let folder = FileManager.default.temporaryDirectory.appending(path: "Share-\(UUID().uuidString)")
            let url = folder.appending(path: "\(safe).\(PackFile.fileExtension)")
            do {
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                try file.encoded().write(to: url, options: .atomic)
                return url
            } catch {
                return nil
            }
        }.value
    }

    /// Writes the two files of a challenge: the finished picture and the pack file, in one temporary folder.
    /// The caller removes the folder after the share. Nil when the pack is not in storage or a write fails.
    func challengeFiles(strip: Data, packID: String) async -> [URL]? {
        guard let pack = await exportFile(packID: packID) else { return nil }
        return await Task.detached {
            let picture = pack.deletingLastPathComponent().appending(path: "PEEK strip.jpg")
            do {
                try strip.write(to: picture, options: .atomic)
                return [picture, pack]
            } catch {
                try? FileManager.default.removeItem(at: pack.deletingLastPathComponent())
                return nil
            }
        }.value
    }

    /// Reads a pack file that came from a different phone. The file is not trusted.
    /// Nil when the file is too large, is not a pack file, is damaged, or has media that the app does not accept.
    func readPackFile(at url: URL) async -> PackFile? {
        let file = await Task.detached { () -> PackFile? in
            let isScoped = url.startAccessingSecurityScopedResource()
            defer {
                if isScoped {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            // The size is checked before the read, so a very large file does not fill the memory.
            defer {
                // The system puts an opened file in the Inbox folder of the app. The file has video of people,
                // so the copy goes away after the read. A file in a different place is not the app's to remove.
                let path = url.standardizedFileURL.path
                if path.hasPrefix(NSHomeDirectory()), path.contains("/Inbox/") {
                    try? FileManager.default.removeItem(at: url)
                }
            }
            guard let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size <= PackFile.maximumBytes,
                  let data = try? Data(contentsOf: url, options: .mappedIfSafe)
            else { return nil }
            return try? PackFile(data: data)
        }.value
        guard let file, await checkMedia(file) else { return nil }
        return file
    }

    /// Removes a customer pack from storage and from the catalog.
    func delete(packID: String) async {
        guard let store, let id = Self.uuid(of: packID) else { return }
        try? await store.deletePack(id)
        await load()
    }
}
