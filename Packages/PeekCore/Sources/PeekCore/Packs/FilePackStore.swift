import Foundation

/// Keeps the packs of the customer in a directory on the device: one folder for each pack, with `pack.json`
/// and a `media` folder. The layout follows `FileDraftStore`.
public actor FilePackStore: PackStore {
    private let directory: URL
    private let files = FileManager()

    public init(directory: URL) {
        self.directory = directory
    }

    private nonisolated func packDirectory(_ id: UserPack.ID) -> URL {
        directory.appending(path: id.uuidString, directoryHint: .isDirectory)
    }

    private nonisolated func mediaDirectory(_ id: UserPack.ID) -> URL {
        packDirectory(id).appending(path: "media", directoryHint: .isDirectory)
    }

    private nonisolated func recordURL(_ id: UserPack.ID) -> URL {
        packDirectory(id).appending(path: "pack.json")
    }

    /// A media name is one file name. A name with a path separator could point outside the pack folder.
    private static func isFileName(_ name: String) -> Bool {
        !name.isEmpty && name != "." && name != ".." && !name.contains("/")
    }

    public nonisolated func mediaURL(named name: String, for packID: UserPack.ID) -> URL {
        mediaDirectory(packID).appending(path: name)
    }

    public func writeMedia(_ data: Data, named name: String, for packID: UserPack.ID) throws {
        guard Self.isFileName(name) else { throw CocoaError(.fileWriteInvalidFileName) }
        try files.createDirectory(at: mediaDirectory(packID), withIntermediateDirectories: true)
        try data.write(to: mediaURL(named: name, for: packID), options: .atomic)
    }

    public func commit(_ pack: UserPack) throws {
        guard pack.mediaFiles.allSatisfy(Self.isFileName) else { throw CocoaError(.fileWriteInvalidFileName) }
        try files.createDirectory(at: packDirectory(pack.id), withIntermediateDirectories: true)
        try JSONEncoder().encode(pack).write(to: recordURL(pack.id), options: .atomic)
        // A pose that was recorded again leaves its old files. The record does not use them.
        let used = pack.mediaFiles
        for name in (try? files.contentsOfDirectory(atPath: mediaDirectory(pack.id).path)) ?? [] where !used.contains(name) {
            try? files.removeItem(at: mediaURL(named: name, for: pack.id))
        }
    }

    public func loadPacks() throws -> [UserPack] {
        let folders = (try? files.contentsOfDirectory(atPath: directory.path)) ?? []
        return folders
            .compactMap(UUID.init(uuidString:))
            .compactMap { id -> UserPack? in
                guard
                    let data = try? Data(contentsOf: recordURL(id)),
                    let pack = try? JSONDecoder().decode(UserPack.self, from: data),
                    // The folder name is the identity. A record with a different ID was not written by this store.
                    pack.id == id,
                    pack.mediaFiles.allSatisfy({ Self.isFileName($0) && files.fileExists(atPath: mediaURL(named: $0, for: id).path) })
                else { return nil }
                return pack
            }
            .sorted { ($0.name, $0.id.uuidString) < ($1.name, $1.id.uuidString) }
    }

    public func deletePack(_ id: UserPack.ID) throws {
        guard files.fileExists(atPath: packDirectory(id).path) else { return }
        try files.removeItem(at: packDirectory(id))
    }
}
