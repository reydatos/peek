import Foundation

/// Durable storage for drafts. Milestone M2 supplies the implementation.
///
/// Contract from PRD section 5: write the media bytes first, then commit the metadata that
/// references them. A crash between the two steps must leave the last accepted state intact.
public protocol DraftStore: Sendable {
    func writeMedia(_ data: Data, for take: Take) async throws
    func commit(_ session: SessionRecord) async throws
    func loadDraft() async throws -> SessionRecord?
    func deleteMedia(for take: Take) async throws
    func deleteDraft(_ id: SessionRecord.ID) async throws
}
