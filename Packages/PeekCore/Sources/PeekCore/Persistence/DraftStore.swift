import Foundation

/// Durable storage for one draft.
///
/// Contract from PRD section 5: write the media bytes first, then commit the metadata that
/// references them. A crash between the two steps must leave the last accepted state intact.
public protocol DraftStore: Sendable {
    func writeMedia(_ data: Data, for take: Take) async throws
    func media(for take: Take) async throws -> Data
    func commit(_ session: SessionRecord) async throws
    /// The committed draft. A take with no media is cleared from its slot.
    func loadDraft() async throws -> SessionRecord?
    func deleteMedia(for take: Take) async throws
    func deleteDraft(_ id: SessionRecord.ID) async throws
}
