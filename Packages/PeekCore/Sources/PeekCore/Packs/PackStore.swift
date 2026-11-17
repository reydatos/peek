import Foundation

/// Storage for the pose packs of the customer.
///
/// The media of a pack goes to storage first, then the record. So a record never names a file that is not there.
public protocol PackStore: Sendable {
    /// Writes the bytes of one media file of a pack.
    func writeMedia(_ data: Data, named name: String, for packID: UserPack.ID) async throws
    /// Stores the record of a pack, and removes the media files of the pack that the record does not use.
    func commit(_ pack: UserPack) async throws
    /// The stored packs, by name. A pack that has a missing media file is left out.
    func loadPacks() async throws -> [UserPack]
    func deletePack(_ id: UserPack.ID) async throws
    /// Where a media file of a pack is. The file can be absent.
    nonisolated func mediaURL(named name: String, for packID: UserPack.ID) -> URL
}
