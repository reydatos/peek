import Foundation

/// Keeps one draft in a directory on the device: `draft.json` and one media file for each take.
public actor FileDraftStore: DraftStore {
    private let directory: URL
    private let files = FileManager()

    public init(directory: URL) {
        self.directory = directory
    }

    private var mediaDirectory: URL {
        directory.appending(path: "media", directoryHint: .isDirectory)
    }

    private var recordURL: URL {
        directory.appending(path: "draft.json")
    }

    private func mediaURL(_ take: Take) -> URL {
        mediaDirectory.appending(path: take.assetName)
    }

    public func writeMedia(_ data: Data, for take: Take) throws {
        try files.createDirectory(at: mediaDirectory, withIntermediateDirectories: true)
        try data.write(to: mediaURL(take), options: .atomic)
    }

    public func media(for take: Take) throws -> Data {
        try Data(contentsOf: mediaURL(take))
    }

    public func commit(_ session: SessionRecord) throws {
        try files.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(session).write(to: recordURL, options: .atomic)
    }

    /// Loads the committed draft and removes the media files that it does not reference.
    public func loadDraft() throws -> SessionRecord? {
        guard files.fileExists(atPath: recordURL.path) else {
            try? files.removeItem(at: mediaDirectory)
            return nil
        }
        var record = try JSONDecoder().decode(SessionRecord.self, from: Data(contentsOf: recordURL))
        record.slots = record.slots.map { slot in
            Slot(id: slot.id, cueID: slot.cueID, acceptedTake: existing(slot.acceptedTake), previousTake: existing(slot.previousTake))
        }
        let used = Set(record.slots.flatMap { [$0.acceptedTake, $0.previousTake] }.compactMap { $0?.assetName })
        for name in (try? files.contentsOfDirectory(atPath: mediaDirectory.path)) ?? [] where !used.contains(name) {
            try? files.removeItem(at: mediaDirectory.appending(path: name))
        }
        return record
    }

    private func existing(_ take: Take?) -> Take? {
        take.flatMap { files.fileExists(atPath: mediaURL($0).path) ? $0 : nil }
    }

    public func deleteMedia(for take: Take) throws {
        guard files.fileExists(atPath: mediaURL(take).path) else { return }
        try files.removeItem(at: mediaURL(take))
    }

    public func deleteDraft(_ id: SessionRecord.ID) throws {
        guard files.fileExists(atPath: recordURL.path) else { return }
        let record = try? JSONDecoder().decode(SessionRecord.self, from: Data(contentsOf: recordURL))
        guard record == nil || record?.id == id else { return }
        try files.removeItem(at: recordURL)
        try? files.removeItem(at: mediaDirectory)
    }
}
